// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.framebuffer;

// import std.string: toStringz, fromStringz;
// import std.file: read;

import faux.vk.lib;

import faux.vk.context;
import faux.vk.commandbuffer;
import faux.vk.swapchain;
import faux.vk.uniformbuffer;

import faux.log;

void createFramebuffers(ref VkContext vk) {
    VkFramebuffer[] swapChainFramebuffers = new VkFramebuffer[](vk.swapChainImageViews.length);

    for (size_t i = 0; i < vk.swapChainImageViews.length; ++i) {
        VkImageView[3] attachments = [
            vk.colorImageView,
            vk.depthImageView,
            vk.swapChainImageViews[i] // now resolve buffer
        ];

        VkFramebufferCreateInfo framebufferInfo;
        framebufferInfo.renderPass = vk.renderPass;
        framebufferInfo.attachmentCount = cast(uint) attachments.length;
        framebufferInfo.pAttachments = attachments.ptr;
        framebufferInfo.width = vk.swapChainExtent.width;
        framebufferInfo.height = vk.swapChainExtent.height;
        framebufferInfo.layers = 1;

        VkResult result = vkCreateFramebuffer(vk.device, &framebufferInfo, null, &swapChainFramebuffers[i]);
        if (result != VK_SUCCESS) {
            error("Failed to create framebuffer - ", result);
        }
    }

    vk.swapChainFramebuffers = swapChainFramebuffers;

    info("Successfully created ", vk.swapChainImageViews.length, " framebuffers");
}

void createSyncObjects(ref VkContext vk) {
    VkSemaphore[] imageAvailableSemaphores = new VkSemaphore[](vk.framesInFlight);
    VkSemaphore[] renderFinishedSemaphores = new VkSemaphore[](vk.framesInFlight);
    VkFence[] inFlightFences = new VkFence[](vk.framesInFlight);

    VkSemaphoreCreateInfo semaphoreInfo;
    VkFenceCreateInfo fenceInfo;
    fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

    for (int i = 0; i < vk.framesInFlight; ++i) {
        VkResult result;
        result = vkCreateSemaphore(vk.device, &semaphoreInfo, null, &imageAvailableSemaphores[i]);
        if (result != VK_SUCCESS) {
            error("Failed to create semaphore - ", result);
        }
        result = vkCreateSemaphore(vk.device, &semaphoreInfo, null, &renderFinishedSemaphores[i]);
        if (result != VK_SUCCESS) {
            error("Failed to create semaphore - ", result);
        }
        result = vkCreateFence(vk.device, &fenceInfo, null, &inFlightFences[i]);
        if (result != VK_SUCCESS) {
            error("Failed to create fence - ", result);
        }
    }
    vk.imageAvailableSemaphores = imageAvailableSemaphores;
    vk.renderFinishedSemaphores = renderFinishedSemaphores;
    vk.inFlightFences = inFlightFences;

    info("Successfully created sync objects");
}

void drawFrame(ref VkContext vk) {
    vkWaitForFences(vk.device, 1, &vk.inFlightFences[vk.currentFrame], VK_TRUE, uint64_t.max);

    uint imageIndex;
    VkResult acquireResult = vkAcquireNextImageKHR(
        vk.device,
        vk.swapChain,
        uint64_t.max,
        vk.imageAvailableSemaphores[vk.currentFrame],
        VK_NULL_HANDLE,
        &imageIndex
    );

    if (acquireResult == VK_ERROR_OUT_OF_DATE_KHR) {
        recreateSwapChain(vk);
        return;
    } else
    if (acquireResult != VK_SUCCESS && acquireResult != VK_SUBOPTIMAL_KHR) {
        error("Failed to acquire swap chain image - ", acquireResult);
    }

    // Resetting only after to avoid deadlock
    vkResetFences(vk.device, 1, &vk.inFlightFences[vk.currentFrame]);

    vkResetCommandBuffer(vk.commandBuffers[vk.currentFrame], 0);
    recordCommandBuffer(vk, imageIndex);

    updateUniformBuffer(vk, vk.currentFrame);

    VkSubmitInfo submitInfo;
    VkSemaphore[] waitSemaphores = [vk.imageAvailableSemaphores[vk.currentFrame]];
    VkPipelineStageFlags[] waitStages = [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT];
    submitInfo.waitSemaphoreCount = cast(uint) waitSemaphores.length;
    submitInfo.pWaitSemaphores = waitSemaphores.ptr;
    submitInfo.pWaitDstStageMask = waitStages.ptr;

    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &vk.commandBuffers[vk.currentFrame];

    VkSemaphore[] signalSemaphores = [vk.renderFinishedSemaphores[vk.currentFrame]];
    submitInfo.signalSemaphoreCount = cast(uint) signalSemaphores.length;
    submitInfo.pSignalSemaphores = signalSemaphores.ptr;

    VkResult submitResult = vkQueueSubmit(vk.graphicsQueue, 1, &submitInfo, vk.inFlightFences[vk.currentFrame]);
    if (submitResult != VK_SUCCESS) {
        error("Failed to submit draw command buffer - ", submitResult);
    }

    VkPresentInfoKHR presentInfo;
    presentInfo.waitSemaphoreCount = cast(uint) signalSemaphores.length;
    presentInfo.pWaitSemaphores = signalSemaphores.ptr;

    VkSwapchainKHR[] swapChains = [vk.swapChain];
    presentInfo.swapchainCount = 1;
    presentInfo.pSwapchains = swapChains.ptr;
    presentInfo.pImageIndices = &imageIndex;

    // presentInfo.pResults = null;

    VkResult presentResult = vkQueuePresentKHR(vk.presentQueue, &presentInfo);
    if (presentResult == VK_ERROR_OUT_OF_DATE_KHR || presentResult == VK_SUBOPTIMAL_KHR || vk.framebufferResized) {
        vk.framebufferResized = false;
        recreateSwapChain(vk);
    } else
    if (presentResult != VK_SUCCESS) {
        error("Failed to present swap chain image - ", presentResult);
    }

    vk.currentFrame = (vk.currentFrame + 1) % vk.framesInFlight;
}
