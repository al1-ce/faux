// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.uniformbuffer;

import std.datetime;
import std.math: PI;
import core.stdc.string: memcpy;

import faux.vk.lib;
import faux.sdl.lib: SDL_GetTicks;

import faux.vk.context;
import faux.vk.vertex;

import sily.matrix;
import sily.vector;

import faux.log;

struct UniformBufferObject {
    float[16] model;
    float[16] view;
    float[16] proj;
}

void createDescriptorSetLayout(ref VkContext vk) {
    VkDescriptorSetLayoutBinding uboLayoutBinding;
    uboLayoutBinding.binding = 0;
    uboLayoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    uboLayoutBinding.descriptorCount = 1;
    uboLayoutBinding.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
    uboLayoutBinding.pImmutableSamplers = null;

    VkDescriptorSetLayoutBinding samplerLayoutBinding;
    samplerLayoutBinding.binding = 1;
    samplerLayoutBinding.descriptorCount = 1;
    samplerLayoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    samplerLayoutBinding.pImmutableSamplers = null;
    samplerLayoutBinding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;

    VkDescriptorSetLayoutBinding[] bindings = [uboLayoutBinding, samplerLayoutBinding];

    VkDescriptorSetLayoutCreateInfo layoutInfo;
    layoutInfo.bindingCount = cast(uint) bindings.length;
    layoutInfo.pBindings = bindings.ptr;

    VkDescriptorSetLayout descriptorSetLayout;

    VkResult layoutResult = vkCreateDescriptorSetLayout(vk.device, &layoutInfo, null, &descriptorSetLayout);
    if (layoutResult != VK_SUCCESS) {
        error("Failed to create descriptor set layout - ", layoutResult);
    }
    vk.descriptorSetLayout = descriptorSetLayout;

    info("Successfully created descriptor set layout");
}

void createUniformBuffers(ref VkContext vk) {
    VkDeviceSize bufferSize = UniformBufferObject.sizeof;

    vk.uniformBuffers = new VkBuffer[](vk.framesInFlight);
    vk.uniformBuffersMemory = new VkDeviceMemory[](vk.framesInFlight);
    vk.uniformBuffersMapped = new void*[](vk.framesInFlight);

    for (int i = 0; i < vk.framesInFlight; ++i) {
        createBuffer(vk, bufferSize,
            VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
            VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            vk.uniformBuffers[i],
            vk.uniformBuffersMemory[i]
        );

        vkMapMemory(vk.device, vk.uniformBuffersMemory[i], 0, bufferSize, 0, &vk.uniformBuffersMapped[i]);
    }
}

void updateUniformBuffer(ref VkContext vk, uint currentImage) {
    float currentTime = SDL_GetTicks() * 0.001;
    float time = currentTime - vk.startTime;

    UniformBufferObject ubo;
    vec3 center = vec3(0, -17, 0);
    ubo.model = (         mat4.translation(center) *
        mat4.translation(-center) *
        mat4.rotationZ(time * PI / 2.0) *
        mat4.translation(center)
        ).buffer();
        // mat4.rotationZ(time * PI / 2.0).buffer();
    // ubo.model = mat4.identity().buffer();
    // ubo.model = mat4.translation(0, -17, 0).buffer();
    // z up -x forward y right i think
    ubo.view = mat4.lookAt(
        // vec3(0.1, 0, 30),
        vec3(25, 0, 25),
        vec3(0, 0, 0),
        vec3(0, 0, 1)
        // vec3(0, 2, -4),
        // vec3(0, 0, 0),
        // vec3(0, 1, 0)
    ).buffer();
    mat4 proj = mat4.perspective(
        95,
        vk.swapChainExtent.width / cast(float) vk.swapChainExtent.height,
        0.1f, 100.0f
    );

    // LINK: https://www.saschawillems.de/blog/2019/03/29/flipping-the-vulkan-viewport/
    // Maybe that or I'll have to figure out martices
    proj[1][1] *= -1;
    ubo.proj = proj.buffer();
    memcpy(vk.uniformBuffersMapped[currentImage], &ubo, ubo.sizeof);
}

float degToRad(float deg) => deg * PI / 180;
float radToDeg(float rad) => (180 * rad) / PI;

void createDescriptorPool(ref VkContext vk) {
    VkDescriptorPoolSize[2] poolSizes;
    poolSizes[0].type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    poolSizes[0].descriptorCount = vk.framesInFlight;
    poolSizes[1].type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    poolSizes[1].descriptorCount = vk.framesInFlight;

    VkDescriptorPoolCreateInfo poolInfo;
    poolInfo.poolSizeCount = cast(uint) poolSizes.length;
    poolInfo.pPoolSizes = poolSizes.ptr;
    poolInfo.maxSets = vk.framesInFlight;

    VkDescriptorPool descriptorPool;
    VkResult poolResult = vkCreateDescriptorPool(vk.device, &poolInfo, null, &descriptorPool);
    if (poolResult != VK_SUCCESS) {
        error("Failed to create descriptor pool - ", poolResult);
    }
    vk.descriptorPool = descriptorPool;

    info("Successfully created descriptor pool");
}

void createDescriptorSets(ref VkContext vk) {
    VkDescriptorSetLayout[] layouts = new VkDescriptorSetLayout[](vk.framesInFlight);
    for (int i = 0; i < layouts.length; ++i ) layouts[i] = vk.descriptorSetLayout;

    VkDescriptorSetAllocateInfo allocInfo;
    allocInfo.descriptorPool = vk.descriptorPool;
    allocInfo.descriptorSetCount  = vk.framesInFlight;
    allocInfo.pSetLayouts = layouts.ptr;

    vk.descriptorSets = new VkDescriptorSet[](vk.framesInFlight);
    VkResult descriptorResult = vkAllocateDescriptorSets(vk.device, &allocInfo, vk.descriptorSets.ptr);
    if (descriptorResult != VK_SUCCESS) {
        error("Failed to allocate descriptor sets - ", descriptorResult);
    }

    info("Successfully allocated descriptor sets");

    for (int i = 0; i < vk.framesInFlight; ++i) {
        VkDescriptorBufferInfo bufferInfo;
        bufferInfo.buffer = vk.uniformBuffers[i];
        bufferInfo.offset = 0;
        bufferInfo.range = UniformBufferObject.sizeof;

        VkDescriptorImageInfo imageInfo;
        imageInfo.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
        imageInfo.imageView = vk.textureImageView;
        imageInfo.sampler = vk.textureSampler;

        VkWriteDescriptorSet[2] descriptorWrites;
        descriptorWrites[0].dstSet = vk.descriptorSets[i];
        descriptorWrites[0].dstBinding = 0;
        descriptorWrites[0].dstArrayElement = 0;
        descriptorWrites[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
        descriptorWrites[0].descriptorCount = 1;
        descriptorWrites[0].pBufferInfo = &bufferInfo;

        descriptorWrites[1].dstSet = vk.descriptorSets[i];
        descriptorWrites[1].dstBinding = 1;
        descriptorWrites[1].dstArrayElement = 0;
        descriptorWrites[1].descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
        descriptorWrites[1].descriptorCount = 1;
        descriptorWrites[1].pImageInfo = &imageInfo;

        vkUpdateDescriptorSets(vk.device, cast(uint) descriptorWrites.length, descriptorWrites.ptr, 0, null);
    }
}


