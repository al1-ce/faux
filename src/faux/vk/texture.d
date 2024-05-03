// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.texture;

import core.stdc.string: memcpy;

import std.math: log2, floor;
import std.algorithm.comparison: max, clamp;

import faux.vk.lib;
// import stb.image.binding;

import faux.vk.context;
import faux.vk.vertex;
import faux.vk.imageview;

import faux.log;

void createTextureImage(ref VkContext vk) {
    int texWidth, texHeight, texChannels;

    ubyte* pixels; // = stbi_load(vk.texturePath.ptr, &texWidth, &texHeight, &texChannels, STBI_rgb_alpha);
    VkDeviceSize imageSize = texWidth * texHeight * 4;
    vk.mipLevels = cast(uint) floor(log2(cast(double) max(texWidth, texHeight))) + 1;

    if (!pixels) {
        error("Failed to load texture image");
    }

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;

    createBuffer(
        vk, imageSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        stagingBuffer, stagingBufferMemory
    );

    void* data;
    vkMapMemory(vk.device, stagingBufferMemory, 0, imageSize, 0, &data);
    memcpy(data, pixels, cast(size_t) imageSize);
    vkUnmapMemory(vk.device, stagingBufferMemory);

    // stbi_image_free(pixels);

    VkImage textureImage;
    VkDeviceMemory textureImageMemory;
    createImage(vk, texWidth, texHeight, vk.mipLevels,
                VK_SAMPLE_COUNT_1_BIT, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_TILING_OPTIMAL,
                VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
                VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                textureImage, textureImageMemory);

    transitionImageLayout(vk, textureImage, VK_FORMAT_R8G8B8A8_SRGB, VK_IMAGE_LAYOUT_UNDEFINED,
                          VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.mipLevels);
    copyBufferToImage(vk, stagingBuffer, textureImage, texWidth, texHeight);
    // done when generating mipmaps
    // transitionImageLayout(vk, textureImage, VK_FORMAT_R8G8B8A8_SRGB,
    //                       VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    //                       VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.mipLevels);
    generateMipmaps(vk, textureImage, VK_FORMAT_R8G8B8A8_SRGB, texWidth, texHeight, vk.mipLevels);

    vk.textureImage = textureImage;
    vk.textureImageMemory = textureImageMemory;

    vkDestroyBuffer(vk.device, stagingBuffer, null);
    vkFreeMemory(vk.device, stagingBufferMemory, null);
}

void createImage(ref VkContext vk, uint width, uint height,
                 uint mipLevels, VkSampleCountFlagBits numSamples,
                 VkFormat format, VkImageTiling tiling,
                 VkImageUsageFlags usage, VkMemoryPropertyFlags properties,
                 ref VkImage image, ref VkDeviceMemory imageMemory) {
    VkImageCreateInfo imageInfo;
    imageInfo.imageType = VK_IMAGE_TYPE_2D;
    imageInfo.extent.width = width;
    imageInfo.extent.height = height;
    imageInfo.extent.depth = 1;
    imageInfo.mipLevels = mipLevels;
    imageInfo.arrayLayers = 1;
    imageInfo.format = format;
    // For access to pixels use VK_IMAGE_TILING_LINEAR and VK_IMAGE_TILING_PREINITIALIZED
    imageInfo.tiling = tiling;
    imageInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    imageInfo.usage = usage;
    imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    imageInfo.samples = numSamples;
    imageInfo.flags = 0;

    VkResult imageResult = vkCreateImage(vk.device, &imageInfo, null, &image);
    if (imageResult != VK_SUCCESS) {
        error("Failed to create image - ", imageResult);
    }

    VkMemoryRequirements memRequirements;
    vkGetImageMemoryRequirements(vk.device, image, &memRequirements);

    VkMemoryAllocateInfo allocInfo;
    allocInfo.allocationSize = memRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(vk, memRequirements.memoryTypeBits, properties);

    VkResult allocResult = vkAllocateMemory(vk.device, &allocInfo, null, &imageMemory);
    if (allocResult != VK_SUCCESS) {
        error("Failed to allocate image memory - ", allocResult);
    }

    vkBindImageMemory(vk.device, image, imageMemory, 0);

    info("Successfully created image");
}

void transitionImageLayout(ref VkContext vk, VkImage image, VkFormat format,
                           VkImageLayout oldLayout, VkImageLayout newLayout, uint mipLevels) {
    VkCommandBuffer commandBuffer = beginSingleTimeCommands(vk);

    VkImageMemoryBarrier barrier;
    barrier.oldLayout = oldLayout;
    barrier.newLayout = newLayout;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = image;
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseMipLevel = 0;
    barrier.subresourceRange.levelCount = mipLevels;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;

    VkPipelineStageFlags sourceStage;
    VkPipelineStageFlags destinationStage;

    if (oldLayout == VK_IMAGE_LAYOUT_UNDEFINED && newLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
        barrier.srcAccessMask = 0;
        barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

        sourceStage = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        destinationStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
    } else if (oldLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL &&
               newLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
        barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
        barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

        sourceStage = VK_PIPELINE_STAGE_TRANSFER_BIT;
        destinationStage = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
    } else {
        error("Unsupported layout transition from ", oldLayout.stringof, " to ", newLayout.stringof);
    }

    vkCmdPipelineBarrier(
        commandBuffer,
        sourceStage, destinationStage,
        0,
        0, null,
        0, null,
        1, &barrier
    );

    endSingleTimeCommands(vk, commandBuffer);
}

void createTextureImageView(ref VkContext vk) {
    vk.textureImageView = createImageView(vk, vk.textureImage, VK_FORMAT_R8G8B8A8_SRGB,
            VK_IMAGE_ASPECT_COLOR_BIT, vk.mipLevels);
}

void copyBufferToImage(ref VkContext vk, VkBuffer buffer, VkImage image, uint width, uint height) {
    VkCommandBuffer commandBuffer = beginSingleTimeCommands(vk);

    VkBufferImageCopy region;
    region.bufferOffset = 0;
    region.bufferRowLength = 0;
    region.bufferImageHeight = 0;

    region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    region.imageSubresource.mipLevel = 0;
    region.imageSubresource.baseArrayLayer = 0;
    region.imageSubresource.layerCount = 1;

    region.imageOffset = VkOffset3D(0, 0, 0);
    region.imageExtent = VkExtent3D(width, height, 1);

    vkCmdCopyBufferToImage(commandBuffer, buffer, image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    endSingleTimeCommands(vk, commandBuffer);
}

void createTextureSampler(ref VkContext vk) {
    VkSamplerCreateInfo samplerInfo;
    samplerInfo.magFilter = VK_FILTER_LINEAR;
    samplerInfo.minFilter = VK_FILTER_LINEAR;
    samplerInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_REPEAT;
    samplerInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_REPEAT;
    samplerInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_REPEAT;
    samplerInfo.anisotropyEnable = VK_TRUE;

    VkPhysicalDeviceProperties properties;
    vkGetPhysicalDeviceProperties(vk.physicalDevice, &properties);

    samplerInfo.maxAnisotropy = properties.limits.maxSamplerAnisotropy;
    samplerInfo.borderColor = VK_BORDER_COLOR_INT_OPAQUE_BLACK;
    samplerInfo.unnormalizedCoordinates = VK_FALSE;
    samplerInfo.compareEnable = VK_FALSE;
    samplerInfo.compareOp = VK_COMPARE_OP_ALWAYS;
    samplerInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
    samplerInfo.mipLodBias = 0.0f;
    samplerInfo.minLod = 0.0f;
    // samplerInfo.minLod = cast(float) vk.mipLevels / 2.0;
    samplerInfo.maxLod = cast(float) vk.mipLevels;

    VkSampler textureSampler;
    VkResult samplerResult = vkCreateSampler(vk.device, &samplerInfo, null, &textureSampler);
    if (samplerResult != VK_SUCCESS) {
        error("Failed to create texture sampler - ", samplerResult);
    }
    vk.textureSampler = textureSampler;

    info("Successfully created texture sampler");
}

void createDepthResources(ref VkContext vk) {
    VkFormat depthFormat = findDepthFormat(vk);
    createImage(
        vk, vk.swapChainExtent.width, vk.swapChainExtent.height,
        1, vk.msaaSamples, depthFormat,
        VK_IMAGE_TILING_OPTIMAL, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
        VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        vk.depthImage, vk.depthImageMemory
    );

    vk.depthImageView = createImageView(vk, vk.depthImage, depthFormat, VK_IMAGE_ASPECT_DEPTH_BIT, 1);
    // TODO: Explicitly transitioning the depth image
    // LINK: https://vulkan-tutorial.com/Depth_buffering
}

void createColorResources(ref VkContext vk) {
    VkFormat colorFormat = vk.swapChainImageFormat;

    createImage(
        vk, vk.swapChainExtent.width, vk.swapChainExtent.height,
        1, vk.msaaSamples, colorFormat,
        VK_IMAGE_TILING_OPTIMAL,
        VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT |
        VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        vk.colorImage, vk.colorImageMemory
    );

    vk.colorImageView = createImageView(vk, vk.colorImage, colorFormat, VK_IMAGE_ASPECT_COLOR_BIT, 1);
}

VkFormat findDepthFormat(ref VkContext vk) {
    return findSupportedFormat(vk,
        [VK_FORMAT_D32_SFLOAT, VK_FORMAT_D32_SFLOAT_S8_UINT, VK_FORMAT_D24_UNORM_S8_UINT],
        VK_IMAGE_TILING_OPTIMAL,
        VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT
    );
}

// TODO: use to poll stencil in findDepthFormat
bool hasStencilComponent(VkFormat format) {
    return format == VK_FORMAT_D32_SFLOAT_S8_UINT || format == VK_FORMAT_D24_UNORM_S8_UINT;
}

VkFormat findSupportedFormat(ref VkContext vk, VkFormat[] candidates,
                             VkImageTiling tiling, VkFormatFeatureFlags features) {
    foreach (VkFormat format; candidates) {
        VkFormatProperties props;
        vkGetPhysicalDeviceFormatProperties(vk.physicalDevice, format, &props);
        if (tiling == VK_IMAGE_TILING_LINEAR && (props.linearTilingFeatures & features) == features) {
            return format;
        }
        if (tiling == VK_IMAGE_TILING_OPTIMAL && (props.optimalTilingFeatures & features) == features) {
            return format;
        }
    }

    fatal("Failed to find supported format");

    // TODO: technically unreachable statement
    // TODO: damn it, gotta figure out what to do with that
    // return VkFormat();
}

void generateMipmaps(ref VkContext vk, VkImage image,
                     VkFormat imageFormat, int texWidth, int texHeight, uint mipLevels) {
    VkFormatProperties formatProperties;
    vkGetPhysicalDeviceFormatProperties(vk.physicalDevice, imageFormat, &formatProperties);

    // TODO: inefficient. Must implement custom mipmap generation
    if (!(formatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)) {
        error("Texture image format does not support linear blitting");
    }

    VkCommandBuffer commandBuffer = beginSingleTimeCommands(vk);

    VkImageMemoryBarrier barrier;
    barrier.image = image;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;
    barrier.subresourceRange.levelCount = 1;

    int mipWidth = texWidth;
    int mipHeight = texHeight;

    for (uint i = 1; i < mipLevels; ++i) {
        barrier.subresourceRange.baseMipLevel = i - 1;
        barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
        barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
        barrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;

        vkCmdPipelineBarrier(commandBuffer,
            VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT, 0,
            0, null,
            0, null,
            1, &barrier
        );

        VkImageBlit blit;
        blit.srcOffsets[0] = VkOffset3D(0, 0, 0);
        blit.srcOffsets[1] = VkOffset3D(mipWidth, mipHeight, 1);
        blit.srcSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        blit.srcSubresource.mipLevel = i - 1;
        blit.srcSubresource.baseArrayLayer = 0;
        blit.srcSubresource.layerCount = 1;
        blit.dstOffsets[0] = VkOffset3D(0, 0, 0);
        blit.dstOffsets[1] =
            VkOffset3D(
                mipWidth > 1 ? mipWidth / 2 : 1,
                mipHeight > 1 ? mipHeight / 2 : 1,
                1
            );
        blit.dstSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        blit.dstSubresource.mipLevel = i;
        blit.dstSubresource.baseArrayLayer = 0;
        blit.dstSubresource.layerCount = 1;

        // Beware if you are using a dedicated transfer queue (as suggested in Vertex buffers):
        // vkCmdBlitImage must be submitted to a queue with graphics capability.
        vkCmdBlitImage(
            commandBuffer,
            image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            1, &blit,
            VK_FILTER_LINEAR
        );

        barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
        barrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
        barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

        vkCmdPipelineBarrier(
            commandBuffer,
            VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0,
            0, null,
            0, null,
            1, &barrier
        );

        if (mipWidth > 1) mipWidth /= 2;
        if (mipHeight > 1) mipHeight /= 2;
    }

    barrier.subresourceRange.baseMipLevel = mipLevels - 1;
    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;

    vkCmdPipelineBarrier(
        commandBuffer,
        VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0,
        0, null,
        0, null,
        1, &barrier
    );

    endSingleTimeCommands(vk, commandBuffer);
}

