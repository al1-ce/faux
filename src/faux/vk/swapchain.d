// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.swapchain;

import std.algorithm.comparison: clamp;
import std.algorithm.iteration: uniq;
import std.algorithm.sorting: sort;
import std.array: array;

import faux.vk.lib;

import faux.sdl.lib;

import faux.vk.context;
import faux.vk.queue;
import faux.vk.imageview;
import faux.vk.framebuffer;
import faux.vk.texture;

import faux.log;

struct SwapChainSupportDetails {
    VkSurfaceCapabilitiesKHR capabilities;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] presentModes;
}

SwapChainSupportDetails querySwapChainSupport(VkPhysicalDevice device, VkContext vk) {
    SwapChainSupportDetails details;

    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, vk.surface, &details.capabilities);

    uint formatCount;
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, vk.surface, &formatCount, null);

    if (formatCount != 0) {
        details.formats = new VkSurfaceFormatKHR[](formatCount);
        vkGetPhysicalDeviceSurfaceFormatsKHR(device, vk.surface, &formatCount, details.formats.ptr);
    }

    uint presentModeCount;
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, vk.surface, &presentModeCount, null);

    if (presentModeCount != 0) {
        details.presentModes = new VkPresentModeKHR[](presentModeCount);
        vkGetPhysicalDeviceSurfacePresentModesKHR(device, vk.surface, &presentModeCount, details.presentModes.ptr);
    }

    return details;
}

VkSurfaceFormatKHR chooseSwapSurfaceFormat(VkSurfaceFormatKHR[] availableFormats) {
    foreach (format; availableFormats) {
        // apparently bgr
        if (format.format == VK_FORMAT_B8G8R8A8_SRGB && format.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
        // if (format.format == VK_FORMAT_R8G8B8A8_SRGB && format.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return format;
        }
    }
    return availableFormats[0];
}

VkPresentModeKHR chooseSwapPresentMode(VkPresentModeKHR[] availablePresentModes) {
    foreach (mode; availablePresentModes) {
        if (mode == VK_PRESENT_MODE_FIFO_KHR) {
            return mode;
        }
    }
    return VK_PRESENT_MODE_FIFO_KHR;
}

VkExtent2D chooseSwapExtent(VkSurfaceCapabilitiesKHR capabilities, VkContext vk) {
    if (capabilities.currentExtent.width != uint32_t.max) {
        return capabilities.currentExtent;
    } else {
        int width, height;

        // FIXME: extent
        // SDL_Vulkan_GetDrawableSize(vk.window, &width, &height);

        VkExtent2D actualExtent;

        actualExtent.width = clamp(width, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
        actualExtent.height = clamp(height, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);

        return actualExtent;
    }
}

void createSwapChain(ref VkContext vk) {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(vk.physicalDevice, vk);

    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities, vk);

    uint imageCount = swapChainSupport.capabilities.minImageCount + 1;

    if (swapChainSupport.capabilities.maxImageCount > 0 && imageCount > swapChainSupport.capabilities.maxImageCount) {
        imageCount = swapChainSupport.capabilities.maxImageCount;
    }

    VkSwapchainCreateInfoKHR createInfo;
    createInfo.surface = vk.surface;

    createInfo.minImageCount = imageCount;
    createInfo.imageFormat = surfaceFormat.format;
    createInfo.imageColorSpace = surfaceFormat.colorSpace;
    createInfo.imageExtent = extent;
    createInfo.imageArrayLayers = 1; // always 1 unless stereoscopic 3d
    createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    // For later: to use post processing uncomment?
    // createInfo.imageUsage = VK_IMAGE_USAGE_TRANSFER_DST_BIT;

    QueueFamilyIndices indices = findQueueFamilies(vk.physicalDevice, vk);

    uint[] queueFamilyIndices =
        [indices.graphicsFamily.get, indices.presentFamily.get].sort().uniq().array;

    if (indices.graphicsFamily != indices.presentFamily) {
        // To make spicy set it to exclusive mode (needs some complex stuff and owndership)
        createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
        createInfo.queueFamilyIndexCount = 2;
        createInfo.pQueueFamilyIndices = queueFamilyIndices.ptr;
    } else {
        createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
        createInfo.queueFamilyIndexCount = 0;
        createInfo.pQueueFamilyIndices = null;
    }

    // Allows to auto-transform images in swap chain
    createInfo.preTransform = swapChainSupport.capabilities.currentTransform;

    // Blending with other windows? TODO: check
    // createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR;
    createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;

    createInfo.presentMode = presentMode;
    // Ignores obstructed pixels (i.e by another window)
    createInfo.clipped = VK_TRUE;

    // Can be used to reset swapchain on window resize
    createInfo.oldSwapchain = VK_NULL_HANDLE;

    VkSwapchainKHR swapChain;
    VkResult result = vkCreateSwapchainKHR(vk.device, &createInfo, null, &swapChain);
    if (result != VK_SUCCESS) {
        error("Failed to create swap chain - ", result);
    }
    vk.swapChain = swapChain;

    VkImage[] swapChainImages;
    vkGetSwapchainImagesKHR(vk.device, vk.swapChain, &imageCount, null);
    swapChainImages = new VkImage[](imageCount);
    vkGetSwapchainImagesKHR(vk.device, vk.swapChain, &imageCount, swapChainImages.ptr);
    vk.swapChainImages = swapChainImages;

    vk.swapChainImageFormat = surfaceFormat.format;
    vk.swapChainExtent = extent;

    info("Successfully created swap chain");
}

void cleanupSwapChain(ref VkContext vk) {
    vkDestroyImageView(vk.device, vk.colorImageView, null);
    vkDestroyImage(vk.device, vk.colorImage, null);
    vkFreeMemory(vk.device, vk.colorImageMemory, null);

    vkDestroyImageView(vk.device, vk.depthImageView, null);
    vkDestroyImage(vk.device, vk.depthImage, null);
    vkFreeMemory(vk.device, vk.depthImageMemory, null);

    foreach (framebuffer; vk.swapChainFramebuffers) {
        vkDestroyFramebuffer(vk.device, framebuffer, null);
    }

    foreach (imageView; vk.swapChainImageViews) {
        vkDestroyImageView(vk.device, imageView, null);
    }

    vkDestroySwapchainKHR(vk.device, vk.swapChain, null);
}

void recreateSwapChain(ref VkContext vk) {
    int width = 0;
    int height = 0;
    // FIXME: swapchain
    // SDL_GetWindowSize(vk.window, &width, &height);
    while (width == 0 || height == 0) {
        // SDL_GetWindowSize(vk.window, &width, &height);
        SDL_PollEvent(null); // polls events for window size i guess
    }

    vkDeviceWaitIdle(vk.device);

    cleanupSwapChain(vk);

    createSwapChain(vk);
    createImageViews(vk);
    createColorResources(vk);
    createDepthResources(vk);
    createFramebuffers(vk);
}

