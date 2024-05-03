// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.device.physical;

import std.stdio: writeln;
import std.string: fromStringz;
import std.algorithm.sorting: sort;
import std.typecons: Nullable;

import faux.vk.lib;

import faux.vk.queue;
import faux.vk.context;
import faux.vk.swapchain;

import faux.log;

// bool isDeviceSuitable(VkPhysicalDevice device) {
//     VkPhysicalDeviceProperties deviceProperties;
//     vkGetPhysicalDeviceProperties(device, &deviceProperties);
//     VkPhysicalDeviceFeatures deviceFeatures;
//     vkGetPhysicalDeviceFeature(device, &deviceFeatures);
//
//     return
//         deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU &&
//         deviceFeatures.geometryShader;
// }

const(char)*[] deviceExtensions = [
    VK_KHR_SWAPCHAIN_EXTENSION_NAME
];

/// Rates how good device is
int rateDeviceSuitability(VkPhysicalDevice device, ref VkContext vk) {
    VkPhysicalDeviceProperties deviceProperties;
    VkPhysicalDeviceFeatures deviceFeatures;

    vkGetPhysicalDeviceProperties(device, &deviceProperties);
    vkGetPhysicalDeviceFeatures(device, &deviceFeatures);

    if (!deviceFeatures.geometryShader) return 0;
    if (!findQueueFamilies(device, vk).isComplete) return 0;
    if (!checkDeviceExtensionSupport(device)) return 0;

    // MUST QUEUE AFTER CONFIRMING EXTENSION SUPPORT
    // queue waht?
    bool swapChainAdequate = false;
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(device, vk);
    swapChainAdequate = swapChainSupport.formats.length && swapChainSupport.presentModes.length;

    if (!swapChainAdequate) return 0;

    int score = 0;

    if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) score += 1000;
    if (deviceFeatures.samplerAnisotropy) score += 200;
    score += deviceProperties.limits.maxImageDimension2D;

    return score;
}

bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    uint extensionCount;

    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount, null);

    VkExtensionProperties[] availableExtensions = new VkExtensionProperties[](extensionCount);
    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount, availableExtensions.ptr);

    foreach (reqExtension; deviceExtensions) {
        bool found = false;
        foreach (extension; availableExtensions) {
            if (fromStringz(reqExtension) == fromStringz(extension.extensionName)) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }

    return true;
}

struct VulkanDevice {
    int score = 0;
    int index = 0;
    char[] deviceName;
}

/// Check and pick best physical device based on score
void pickPhysicalDevice(ref VkContext vk) {
    info("Initializing physical devices");

    uint deviceCount = 0;
    vkEnumeratePhysicalDevices(vk.instance, &deviceCount, null);

    if (deviceCount == 0) {
        error("Failed to find GPU with Vulkan support");
    }

    info("Found ", deviceCount, " candidates");

    VkPhysicalDevice[] devices = new VkPhysicalDevice[](deviceCount);
    vkEnumeratePhysicalDevices(vk.instance, &deviceCount, devices.ptr);

    VulkanDevice[] deviceScore = new VulkanDevice[](deviceCount);

    info("Available physical devices - ", deviceCount);
    for (int i = 0; i < deviceCount; ++i) {
        VkPhysicalDevice device = devices[i];
        VkPhysicalDeviceProperties deviceProperties;
        vkGetPhysicalDeviceProperties(device, &deviceProperties);

        deviceScore[i] = VulkanDevice(
            rateDeviceSuitability(device, vk),
            i,
            deviceProperties.deviceName.fromStringz
        );

        writeln("    ", deviceProperties.deviceType, " ", deviceProperties.deviceName.fromStringz);
    }

    sort!((a, b) => a.score > b.score)(deviceScore);

    if (deviceScore[0].score > 0) {
        info("Selected physical device - ", deviceScore[0].deviceName, ", score - ", deviceScore[0].score);
        vk.physicalDevice = devices[deviceScore[0].index];
        vk.msaaSamples = getMaxUsableSampleCount(vk);
    } else {
        error("Failed to select suitable GPU, best score - ", deviceScore[0].score);
    }
}

VkSampleCountFlagBits getMaxUsableSampleCount(ref VkContext vk) {
    VkPhysicalDeviceProperties physicalDeviceProperties;
    vkGetPhysicalDeviceProperties(vk.physicalDevice, &physicalDeviceProperties);

    VkSampleCountFlags counts =
        physicalDeviceProperties.limits.framebufferColorSampleCounts &
        physicalDeviceProperties.limits.framebufferDepthSampleCounts;

    if (counts & VK_SAMPLE_COUNT_64_BIT) return VK_SAMPLE_COUNT_64_BIT;
    if (counts & VK_SAMPLE_COUNT_32_BIT) return VK_SAMPLE_COUNT_32_BIT;
    if (counts & VK_SAMPLE_COUNT_16_BIT) return VK_SAMPLE_COUNT_16_BIT;
    if (counts & VK_SAMPLE_COUNT_8_BIT) return VK_SAMPLE_COUNT_8_BIT;
    if (counts & VK_SAMPLE_COUNT_4_BIT) return VK_SAMPLE_COUNT_4_BIT;
    if (counts & VK_SAMPLE_COUNT_2_BIT) return VK_SAMPLE_COUNT_2_BIT;

    return VK_SAMPLE_COUNT_1_BIT;
}

