// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.commandbuffer;

import faux.vk.lib;

import faux.vk.context;
import faux.vk.queue;

import faux.log;

deprecated
void createCommandPool(ref VkContext vk) {
    QueueFamilyIndices queueFamilyIndices = findQueueFamilies(vk.physicalDevice, vk);

    VkCommandPoolCreateInfo poolInfo;
    poolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    poolInfo.queueFamilyIndex = queueFamilyIndices.graphicsFamily.get();

    VkCommandPool commandPool;
    VkResult result = vkCreateCommandPool(vk.device, &poolInfo, null, &commandPool);
    if (result != VK_SUCCESS) {
        error("Failed to create command pool - ", result);
    }
    vk.commandPool = commandPool;
    info("Successfully created command pool");
}

VkCommandPool createCommandPool(VkDevice device, VkPhysicalDevice physicalDevice, VkSurfaceKHR surface) {
    QueueFamilyIndices queueFamilyIndices = findQueueFamilies(physicalDevice, surface);

    VkCommandPoolCreateInfo poolInfo;
    poolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    poolInfo.queueFamilyIndex = queueFamilyIndices.graphicsFamily.get();

    VkCommandPool commandPool;
    VkResult result = vkCreateCommandPool(device, &poolInfo, null, &commandPool);
    if (result != VK_SUCCESS) {
        error("Failed to create command pool - ", result);
    }
    info("Successfully created command pool");
    return commandPool;
}

deprecated
void createCommandBuffers(ref VkContext vk) {
    VkCommandBufferAllocateInfo allocInfo;
    allocInfo.commandPool = vk.commandPool;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandBufferCount = vk.framesInFlight;

    VkCommandBuffer[] commandBuffers = new VkCommandBuffer[](vk.framesInFlight);
    VkResult result = vkAllocateCommandBuffers(vk.device, &allocInfo, commandBuffers.ptr);
    if (result != VK_SUCCESS) {
        error("Failed to create command buffer - ", result);
    }
    vk.commandBuffers = commandBuffers;
    info("Successfully created command buffer");
}

VkCommandBuffer[] createCommandBuffers(VkDevice device, VkCommandPool commandPool, uint framesInFlight) {
    VkCommandBufferAllocateInfo allocInfo;
    allocInfo.commandPool = commandPool;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandBufferCount = framesInFlight;

    VkCommandBuffer[] commandBuffers = new VkCommandBuffer[](framesInFlight);
    VkResult result = vkAllocateCommandBuffers(device, &allocInfo, commandBuffers.ptr);
    if (result != VK_SUCCESS) {
        error("Failed to create command buffer - ", result);
    }
    info("Successfully created command buffer");
    return commandBuffers;
}

void recordCommandBuffer(ref VkContext vk, uint imageIndex) {
    VkCommandBufferBeginInfo beginInfo;
    beginInfo.flags = 0;
    beginInfo.pInheritanceInfo = null;

    VkResult beginInfoResult = vkBeginCommandBuffer(vk.commandBuffers[vk.currentFrame], &beginInfo);
    if (beginInfoResult != VK_SUCCESS) {
        error("Failed to begin recording command buffer");
    }

    VkRenderPassBeginInfo renderPassInfo;
    renderPassInfo.renderPass = vk.renderPass;
    renderPassInfo.framebuffer = vk.swapChainFramebuffers[imageIndex];
    renderPassInfo.renderArea.offset = VkOffset2D(0, 0);
    renderPassInfo.renderArea.extent = vk.swapChainExtent;

    // IMPORTANT! same order as attachments (i.e o_color)
    VkClearValue[2] clearValues;
    clearValues[0].color = VkClearColorValue([0.0f, 0.0f, 0.0f, 1.0f]);
    clearValues[1].depthStencil = VkClearDepthStencilValue(1.0f, 0);

    renderPassInfo.clearValueCount = cast(uint) clearValues.length;
    renderPassInfo.pClearValues = clearValues.ptr;

    vkCmdBeginRenderPass(vk.commandBuffers[vk.currentFrame], &renderPassInfo, VK_SUBPASS_CONTENTS_INLINE);
    vkCmdBindPipeline(vk.commandBuffers[vk.currentFrame], VK_PIPELINE_BIND_POINT_GRAPHICS, vk.graphicsPipeline);

    VkViewport viewport;
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = cast(float) vk.swapChainExtent.width;
    viewport.height = cast(float) vk.swapChainExtent.height;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;
    vkCmdSetViewport(vk.commandBuffers[vk.currentFrame], 0, 1, &viewport);

    VkRect2D scissor;
    scissor.offset = VkOffset2D(0, 0);
    scissor.extent = vk.swapChainExtent;
    vkCmdSetScissor(vk.commandBuffers[vk.currentFrame], 0, 1, &scissor);

    VkBuffer[] vertexBuffers = [vk.vertexBuffer];
    VkDeviceSize[] offsets = [0];
    vkCmdBindVertexBuffers(vk.commandBuffers[vk.currentFrame], 0, 1, vertexBuffers.ptr, offsets.ptr);
    // IMPORTANT: VK_INDEX_TYPE must match ushort/uint index variable
    vkCmdBindIndexBuffer(vk.commandBuffers[vk.currentFrame], vk.indexBuffer, 0, VK_INDEX_TYPE_UINT32);

    vkCmdBindDescriptorSets(
        vk.commandBuffers[vk.currentFrame], VK_PIPELINE_BIND_POINT_GRAPHICS,
        vk.pipelineLayout, 0, 1, &vk.descriptorSets[vk.currentFrame], 0, null
    );
    vkCmdDrawIndexed(vk.commandBuffers[vk.currentFrame], vk.indexSize, 1, 0, 0, 0);
    // vkCmdDraw(vk.commandBuffers[vk.currentFrame], vk.vertexSize, 1, 0, 0);

    vkCmdEndRenderPass(vk.commandBuffers[vk.currentFrame]);

    VkResult result = vkEndCommandBuffer(vk.commandBuffers[vk.currentFrame]);
    if (result != VK_SUCCESS) {
        error("Failed to record command buffer - ", result);
    }
}
