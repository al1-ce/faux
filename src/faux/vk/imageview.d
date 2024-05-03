// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.imageview;

import faux.vk.lib;

import faux.sdl.lib;

import faux.vk.context;

import faux.log;

void createImageViews(ref VkContext vk) {
    VkImageView[] swapChainImageViews = new VkImageView[](vk.swapChainImages.length);

    for (size_t i = 0; i < vk.swapChainImages.length; ++i) {
        swapChainImageViews[i] = createImageView(
            vk, vk.swapChainImages[i], vk.swapChainImageFormat, VK_IMAGE_ASPECT_COLOR_BIT, 1);
    }

    vk.swapChainImageViews = swapChainImageViews;

    info("Successfully created ", vk.swapChainImages.length, " image views");
}

VkImageView createImageView(ref VkContext vk, VkImage image, VkFormat format,
                     VkImageAspectFlags aspectFlags, uint mipLevels) {
    VkImageViewCreateInfo viewInfo;

    viewInfo.image = image;
    viewInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
    viewInfo.format = format;
    viewInfo.subresourceRange.aspectMask = aspectFlags;
    viewInfo.subresourceRange.baseMipLevel = 0;
    viewInfo.subresourceRange.levelCount = mipLevels;
    viewInfo.subresourceRange.baseArrayLayer = 0;
    viewInfo.subresourceRange.layerCount = 1;

    VkImageView view;

    VkResult imageResult = vkCreateImageView(vk.device, &viewInfo, null, &view);
    if (imageResult != VK_SUCCESS) {
        error("Failed to create image view - ", imageResult);
    }

    return view;
}

