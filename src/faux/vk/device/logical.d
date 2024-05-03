// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.device.logical;

// import std.stdio: writeln;
import std.string: fromStringz;
import std.algorithm.iteration: uniq;
import std.algorithm.sorting: sort;
import std.array: array;

// import core.stdcpp.array;

import faux.vk.lib;

import faux.vk.validator: validationLayers;
import faux.vk.queue;
import faux.vk.context;
import faux.vk.device.physical: deviceExtensions;

import faux.log;

void createLogicalDevice(ref VkContext vk) {
    QueueFamilyIndices indices = findQueueFamilies(vk.physicalDevice, vk);

    VkDeviceQueueCreateInfo[] queueCreateInfos;
    uint[] uniqueQueueFamilies =
        [indices.graphicsFamily.get, indices.presentFamily.get].sort().uniq().array;

    float queuePriority = 1.0f;
    foreach (queueFamily; uniqueQueueFamilies) {
        VkDeviceQueueCreateInfo queueCreateInfo;
        queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        queueCreateInfo.queueFamilyIndex = queueFamily;
        queueCreateInfo.queueCount = 1;

        queueCreateInfo.pQueuePriorities = &queuePriority;

        queueCreateInfos ~= queueCreateInfo;
    }

    VkPhysicalDeviceFeatures deviceFeatures;
    deviceFeatures.samplerAnisotropy = VK_TRUE;
    deviceFeatures.sampleRateShading = VK_TRUE;

    VkDeviceCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;

    createInfo.queueCreateInfoCount = cast(uint) queueCreateInfos.length;
    createInfo.pQueueCreateInfos = queueCreateInfos.ptr;

    createInfo.pEnabledFeatures = &deviceFeatures;

    createInfo.enabledExtensionCount = cast(uint) deviceExtensions.length;
    createInfo.ppEnabledExtensionNames = deviceExtensions.ptr;

    if (vk.isDebug) {
        createInfo.enabledLayerCount = cast(uint) validationLayers.length;
        createInfo.ppEnabledLayerNames = validationLayers.ptr;
    } else {
        createInfo.enabledLayerCount = 0;
    }

    VkDevice device;
    VkResult result = vkCreateDevice(vk.physicalDevice, &createInfo, null, &device);
    if (result != VK_SUCCESS) {
        error("Failed to create logical device - ", result);
    }
    vk.device = device;

    if (vk.device == VK_NULL_HANDLE) {
        warning("Vulkan logical device is a NULL handle");
    }

    info("Successfully created logical device");

    // Loads vkDevice, vkQueue and vkCommandBuffer functions
    loadDeviceLevelFunctions(vk.device);

    // Strangely required for logical device to be properly destroyed without segfault
    VkQueue graphicsQueue;
    VkQueue presentQueue;
    vkGetDeviceQueue(vk.device, indices.graphicsFamily.get, 0, &graphicsQueue);
    vkGetDeviceQueue(vk.device, indices.presentFamily.get, 0, &presentQueue);
    vk.graphicsQueue = graphicsQueue;
    vk.presentQueue = presentQueue;

    info("Successfully created queues");
}

