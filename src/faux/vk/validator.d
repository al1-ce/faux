// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.validator;

import std.string: fromStringz;

import faux.vk.lib;

import faux.vk.context;

import faux.log;

const(char*)[] validationLayers = [ "VK_LAYER_KHRONOS_validation" ];

VkResult createDebugUtilsMessengerEXT(
        VkInstance instance,
        const(VkDebugUtilsMessengerCreateInfoEXT*) pCreateInfo,
        const(VkAllocationCallbacks*) pAllocator,
        VkDebugUtilsMessengerEXT* pDebugMessenger) {
    PFN_vkCreateDebugUtilsMessengerEXT func =
        cast(PFN_vkCreateDebugUtilsMessengerEXT)
        vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");

    if (func != null) {
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    } else {
        return VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}

void destroyDebugUtilsMessengerEXT(
        VkInstance instance,
        VkDebugUtilsMessengerEXT pMessenger,
        const(VkAllocationCallbacks*) pAllocator) {
    PFN_vkDestroyDebugUtilsMessengerEXT func =
        cast(PFN_vkDestroyDebugUtilsMessengerEXT)
        vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if (func != null) {
        func(instance, pMessenger, pAllocator);
    }
}


void checkValidationLayerSupport()(bool isDebug) {
    if (!isDebug) return;
    uint layerCount;
    vkEnumerateInstanceLayerProperties(&layerCount, null);

    VkLayerProperties[] availableLayers = new VkLayerProperties[](layerCount);
    vkEnumerateInstanceLayerProperties(&layerCount, availableLayers.ptr);

    // foreach (string layerName; validationLayers) {}
    for (int i = 0; i < validationLayers.length; ++i) {
        const(char*) layerName = validationLayers[i];
        bool layerFound = false;

        foreach (VkLayerProperties prop; availableLayers) {
            if (fromStringz(prop.layerName) == fromStringz(layerName)) {
                layerFound = true;
                break;
            }
        }

        if (!layerFound) {
            error("Validation layer '", validationLayers[i], "' is not available");
        }
    }

    info("Requested validation layers are available");
}
void populateDebugMessengerCreateInfo(VkDebugUtilsMessengerCreateInfoEXT* createInfo) {

    createInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    createInfo.messageSeverity =
                                 VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                                 VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT |
                                 VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT |
                                 VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
                                 0;
    createInfo.messageType =
                             // VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
                             VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
                             VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT |
                             0;
    createInfo.pfnUserCallback = &debugCallback;
    // createInfo.pUserData = null;
}

void setupDebugMessenger(ref VkContext vk) {
    if (!vk.isDebug) return;

    VkDebugUtilsMessengerCreateInfoEXT createInfo;
    populateDebugMessengerCreateInfo(&createInfo);

    VkDebugUtilsMessengerEXT debugMessenger;
    if (createDebugUtilsMessengerEXT(vk.instance, &createInfo, null, &debugMessenger) != VK_SUCCESS) {
        error("Failed to set up debug messenger");
    }
    vk.debugMessenger = debugMessenger;
    info("Successfully set up debug messenger");

}

version(Windows) {
    extern(Windows) 
    uint debugCallback(
            VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
            VkDebugUtilsMessageTypeFlagsEXT messageType,
            const(VkDebugUtilsMessengerCallbackDataEXT)* pCallbackData,
            void* pUserData) @nogc nothrow {
        import core.stdc.stdio: printf;
        char[20] prefix;
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT) prefix = "Note:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT) prefix = "Info:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) prefix = "Warning:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) prefix = "Error:";

        char[20] postfix;
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT) postfix  = "[General]";
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT) postfix = "[Validation]";
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT) postfix = "[Performance]";

        printf("%s %s - %s\n", prefix.ptr, postfix.ptr, pCallbackData.pMessage);

        return VK_FALSE;
    }
} else {
    extern(C)
    uint debugCallback(
            VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
            VkDebugUtilsMessageTypeFlagsEXT messageType,
            const(VkDebugUtilsMessengerCallbackDataEXT)* pCallbackData,
            void* pUserData) @nogc nothrow {
        import core.stdc.stdio: printf;
        char[20] prefix;
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT) prefix = "Note:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT) prefix = "Info:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) prefix = "Warning:";
        if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) prefix = "Error:";

        char[20] postfix;
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT) postfix  = "[General]";
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT) postfix = "[Validation]";
        if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT) postfix = "[Performance]";

        printf("%s %s - %s\n", prefix.ptr, postfix.ptr, pCallbackData.pMessage);

        return VK_FALSE;
    }
}

