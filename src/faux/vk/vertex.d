// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.vertex;

import core.stdc.string: memcpy;

import faux.vk.lib;

import sily.vector;

import faux.vk.context;
import faux.resource.mesh;

import faux.log;

struct Vertex {
    vec3 pos;
    vec3 color;
    vec2 texCoord;

    static VkVertexInputBindingDescription getBindingDescription() {
        VkVertexInputBindingDescription bindingDescription;
        bindingDescription.binding = 0;
        bindingDescription.stride = Vertex.sizeof;
        bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

        return bindingDescription;
    }

    static VkVertexInputAttributeDescription[3] getAttributeDescriptions() {
        VkVertexInputAttributeDescription[3] attributeDescriptions;

        attributeDescriptions[0].binding = 0;
        attributeDescriptions[0].location = 0;
        attributeDescriptions[0].format = VK_FORMAT_R32G32B32_SFLOAT;
        attributeDescriptions[0].offset = Vertex.pos.offsetof;

        attributeDescriptions[1].binding = 0;
        attributeDescriptions[1].location = 1;
        attributeDescriptions[1].format = VK_FORMAT_R32G32B32_SFLOAT;
        attributeDescriptions[1].offset = Vertex.color.offsetof;

        attributeDescriptions[2].binding = 0;
        attributeDescriptions[2].location = 2;
        attributeDescriptions[2].format = VK_FORMAT_R32G32_SFLOAT;
        attributeDescriptions[2].offset = Vertex.texCoord.offsetof;

        return attributeDescriptions;
    }
}

void createBuffer(ref VkContext vk, VkDeviceSize size, VkBufferUsageFlags usage,
                  VkMemoryPropertyFlags properties, ref VkBuffer buffer,
                  ref VkDeviceMemory bufferMemory) {
    VkBufferCreateInfo bufferInfo;
    bufferInfo.size = size;
    bufferInfo.usage = usage;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    VkResult bufferResult = vkCreateBuffer(vk.device, &bufferInfo, null, &buffer);
    if (bufferResult != VK_SUCCESS) {
        error("Failed to create buffer - ", bufferResult);
    }

    VkMemoryRequirements memRequrements;
    vkGetBufferMemoryRequirements(vk.device, buffer, &memRequrements);

    int memType = findMemoryType(vk, memRequrements.memoryTypeBits, properties);
    if (memType == -1) error("Failed to find suitable memory type");

    VkMemoryAllocateInfo allocInfo;
    allocInfo.allocationSize = memRequrements.size;
    allocInfo.memoryTypeIndex = memType;

    // TODO: it's not advised to use vkAllocateMemory
    // need to write own allocator or use something like
    // LINK: https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator
    // see also Conclusion in
    // LINK: https://vulkan-tutorial.com/en/Vertex_buffers/Staging_buffer
    // LINK: https://developer.nvidia.com/vulkan-memory-management
    VkResult memoryResult = vkAllocateMemory(vk.device, &allocInfo, null, &bufferMemory);
    if (memoryResult != VK_SUCCESS) {
        error("Failed to allocate buffer memory - ", memoryResult);
    }

    vkBindBufferMemory(vk.device, buffer, bufferMemory, 0);
    info("Successfully created buffer");
}

void copyBuffer(ref VkContext vk, VkBuffer srcBuffer, VkBuffer dstBuffer, VkDeviceSize size) {
    VkCommandBuffer commandBuffer = beginSingleTimeCommands(vk);

    VkBufferCopy copyRegion;
    copyRegion.srcOffset = 0;
    copyRegion.dstOffset = 0;
    copyRegion.size = size;
    vkCmdCopyBuffer(commandBuffer, srcBuffer, dstBuffer, 1, &copyRegion);

    endSingleTimeCommands(vk, commandBuffer);
}

VkCommandBuffer beginSingleTimeCommands(ref VkContext vk) {
    VkCommandBufferAllocateInfo allocInfo;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandPool = vk.commandPool;
    allocInfo.commandBufferCount = 1;

    VkCommandBuffer commandBuffer;
    vkAllocateCommandBuffers(vk.device, &allocInfo, &commandBuffer);

    VkCommandBufferBeginInfo beginInfo;
    beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    vkBeginCommandBuffer(commandBuffer, &beginInfo);

    return commandBuffer;
}

void endSingleTimeCommands(ref VkContext vk, VkCommandBuffer commandBuffer) {
    vkEndCommandBuffer(commandBuffer);

    VkSubmitInfo submitInfo;
    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &commandBuffer;

    vkQueueSubmit(vk.graphicsQueue, 1, &submitInfo, VK_NULL_HANDLE);
    vkQueueWaitIdle(vk.graphicsQueue);

    vkFreeCommandBuffers(vk.device, vk.commandPool, 1, &commandBuffer);
}

void createVertexBuffer(ref VkContext vk) {
    // Creating two buffers because DEVICE_LOCAL_BIT is more efficient
    // but it doesn't allow for vkMapMemory
    // FIXME: vbuffer
    VkDeviceSize bufferSize = [].sizeof * [].length;
    // VkDeviceSize bufferSize = vk.vertices[0].sizeof * vk.vertices.length;

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;

    createBuffer(vk, bufferSize,
        VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        stagingBuffer, stagingBufferMemory
    );

    void* data;
    vkMapMemory(vk.device, stagingBufferMemory, 0, bufferSize, 0, &data);
    // memcpy(data, vk.vertices.ptr, cast(size_t) bufferSize);
    memcpy(data, [].ptr, cast(size_t) bufferSize);
    vkUnmapMemory(vk.device, stagingBufferMemory);

    createBuffer(vk, bufferSize,
        VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        vk.vertexBuffer, vk.vertexBufferMemory
    );

    copyBuffer(vk, stagingBuffer, vk.vertexBuffer, bufferSize);

    vkDestroyBuffer(vk.device, stagingBuffer, null);
    vkFreeMemory(vk.device, stagingBufferMemory, null);

    // vk.vertexSize = cast(uint) vk.vertices.length;
    vk.vertexSize = cast(uint) [].length;
}

void createIndexBuffer(ref VkContext vk) {
    // VkDeviceSize bufferSize = vk.indices[0].sizeof * vk.indices.length;
    VkDeviceSize bufferSize = 0;

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;

    createBuffer(vk, bufferSize,
        VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        stagingBuffer, stagingBufferMemory
    );

    void* data;
    vkMapMemory(vk.device, stagingBufferMemory, 0, bufferSize, 0, &data);
    memcpy(data, [].ptr, cast(size_t) bufferSize);
    // memcpy(data, vk.indices.ptr, cast(size_t) bufferSize);
    vkUnmapMemory(vk.device, stagingBufferMemory);

    createBuffer(vk, bufferSize,
        VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
        VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        vk.indexBuffer, vk.indexBufferMemory
    );

    copyBuffer(vk, stagingBuffer, vk.indexBuffer, bufferSize);

    vkDestroyBuffer(vk.device, stagingBuffer, null);
    vkFreeMemory(vk.device, stagingBufferMemory, null);

    // vk.indexSize = cast(uint) vk.indices.length;
    vk.indexSize = cast(uint) [].length;
}

int findMemoryType(ref VkContext vk, uint typeFilter, VkMemoryPropertyFlags properties) {
    VkPhysicalDeviceMemoryProperties memProperties;
    vkGetPhysicalDeviceMemoryProperties(vk.physicalDevice, &memProperties);

    for (uint i = 0; i < memProperties.memoryTypeCount; ++i) {
        if (typeFilter & (1 << i) && (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
            return i;
        }
    }

    fatal("Failed to find suitable memory type");
    // return -1;
}

void loadModel(ref VkContext vk) {
    // Mesh mesh = loadObj(vk.modelPath);
    //
    // for (int i = 0; i < mesh.vertexIndices.length; ++i) {
    //     Vertex vert;
    //     vert.pos = mesh.vertices[mesh.vertexIndices[i] - 1][0..3];
    //     vert.texCoord = mesh.uvs[mesh.uvIndices[i] - 1][0..2];
    //     vert.texCoord.y = 1.0 - vert.texCoord.y;
    //     vk.vertices ~= vert;
    //     vk.indices ~= i;
    // }

    // FIXME: change vertex to handle UV indices
}

