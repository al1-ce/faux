// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.queue;

import std.string: fromStringz;
import std.typecons: Nullable;

import faux.vk.lib;

import faux.vk.context;

import faux.log;

struct QueueFamilyIndices {
    Nullable!uint graphicsFamily; // check with .isNull
    Nullable!uint presentFamily;

    @property bool isComplete() {
        return !(graphicsFamily.isNull || presentFamily.isNull);
    }
}

deprecated
QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device, ref VkContext vk) {
    QueueFamilyIndices indices;

    uint queueFamilyCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, null);

    VkQueueFamilyProperties[] queueFamilies = new VkQueueFamilyProperties[](queueFamilyCount);
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.ptr);

    for (int i = 0; i < queueFamilyCount; ++i) {
        if (queueFamilies[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            indices.graphicsFamily = i;
        }

        uint presentSupport = false;
        vkGetPhysicalDeviceSurfaceSupportKHR(device, i, vk.surface, &presentSupport);

        if (presentSupport) {
            indices.presentFamily = i;
        }

        if (indices.isComplete) break;
    }

    return indices;
}

QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device, VkSurfaceKHR surface) {
    QueueFamilyIndices indices;

    uint queueFamilyCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, null);

    VkQueueFamilyProperties[] queueFamilies = new VkQueueFamilyProperties[](queueFamilyCount);
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.ptr);

    for (int i = 0; i < queueFamilyCount; ++i) {
        if (queueFamilies[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            indices.graphicsFamily = i;
        }

        uint presentSupport = false;
        vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);

        if (presentSupport) {
            indices.presentFamily = i;
        }

        if (indices.isComplete) break;
    }

    return indices;
}
