// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.instance;

import std.string: fromStringz;

import faux.sdl.lib: SDL_Window, SDL_Vulkan_GetInstanceExtensions;
import faux.vk.lib;

// import vulkan.validator;
// import vulkan.extensions;
import faux.vk.context;

import faux.log;

/// Creates Vulkan instance and loads extensions
VkInstance createVulkanInstance(SDL_Window* window) {
    // TODO: maybe give user ability to set debug?
    bool isDebug = false; debug isDebug = true;
    checkValidationLayerSupport(isDebug);

    // Get number of global extensions (available? supported?)
    uint extensionCount = 0;
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, null);

    info("Vulkan extensions supported: ", extensionCount);

    // Get actual extension list
    VkExtensionProperties[] extensionProperties = new VkExtensionProperties[](extensionCount);
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, extensionProperties.ptr);

    info("Vulkan supported extensions: ");

    foreach (prop; extensionProperties) {
        // writeln(prop.extensionName.to!(string)().length);
        trace("    ", fromStringz(prop.extensionName), "', ver ", prop.specVersion);
    }

    // This means app will use default vulkan implementation?
    const uint VK_API_VARIANT_DEFAULT = 0;

    // Optional instance info
    VkApplicationInfo appInfo;
    // Erupted has it already set
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "Vulkan Test";
    appInfo.applicationVersion = VK_MAKE_API_VERSION(VK_API_VARIANT_DEFAULT, 0, 0, 1);
    appInfo.pEngineName = "Custom Engine";
    appInfo.engineVersion = VK_MAKE_API_VERSION(VK_API_VARIANT_DEFAULT, 0, 0, 1);
    appInfo.apiVersion = VK_API_VERSION_1_3;

    // Mandatory instance create info
    // Will be used to tell which global extensions
    // and validation layers to use
    VkInstanceCreateInfo createInfo;
    // Erupted has it already set
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo = &appInfo;

    const(char)*[] sdlExtensionNames = getRequiredExtensions(window);

    // Which extensions should be loaded to
    // allow SDL and Vulkan to interface with each other
    createInfo.enabledExtensionCount = cast(uint) sdlExtensionNames.length;
    createInfo.ppEnabledExtensionNames = sdlExtensionNames.ptr;

    VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo;
    if (isDebug) {
        // Passing requested validation layers to Vulkan
        createInfo.enabledLayerCount = cast(uint) validationLayers.length;
        createInfo.ppEnabledLayerNames = validationLayers.ptr;

        populateDebugMessengerCreateInfo(&debugCreateInfo);
        createInfo.pNext = &debugCreateInfo;
    } else {
        createInfo.enabledLayerCount = 0;
    }

    // Creating Vulkan instance
    VkInstance instance;
    VkResult result = vkCreateInstance(&createInfo, null, &instance);

    if (result != VK_SUCCESS) {
        error("Failed to create Vulkan instance - ", result);
    }

    if(instance == VK_NULL_HANDLE) {
        warning("Vulkan instance is a NULL handle");
    }

    info("Successfully created Vulkan instance");

    return instance;
}

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

/// Sets up messanger for valaidation layers
VkDebugUtilsMessengerEXT setupDebugMessenger(VkInstance instance) {
    VkDebugUtilsMessengerCreateInfoEXT createInfo;
    populateDebugMessengerCreateInfo(&createInfo);

    VkDebugUtilsMessengerEXT debugMessenger;
    if (createDebugUtilsMessengerEXT(instance, &createInfo, null, &debugMessenger) != VK_SUCCESS) {
        error("Failed to set up debug messenger");
    }
    info("Successfully set up debug messenger");
    return debugMessenger;
}

// Thanks windows
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

const(char)*[] getRequiredExtensions(SDL_Window* window, bool isDebug = false) {
    uint sdlExtensionCount;
    const(char)*[] sdlExtensionNames;
    // Get count of extensions needed
    SDL_Vulkan_GetInstanceExtensions(window, &sdlExtensionCount, null);
    // What a mess just to get a pointer SDL expects
    sdlExtensionNames = new const(char)*[](sdlExtensionCount);
    // Get actual extension names
    SDL_Vulkan_GetInstanceExtensions(window, &sdlExtensionCount, sdlExtensionNames.ptr);

    if (isDebug) {
        sdlExtensionNames ~= VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
    }

    info("SDL requires ", sdlExtensionNames.length, " extensions");

    for (int i = 0; i < sdlExtensionNames.length; ++i) {
        auto sdlExt = sdlExtensionNames[i];
        const(char)[] name = fromStringz(sdlExt);
        trace("    ", name);

        // if (name == "VK_KHR_metal_surface") *vulkanPlatform = VulkanPlatform.metal;
        // if (name == "VK_KHR_wayland_surface") *vulkanPlatform = VulkanPlatform.wayland;
        // if (name == "VK_KHR_win32_surface") *vulkanPlatform = VulkanPlatform.windows;
        // if (name == "VK_KHR_xcb_surface") *vulkanPlatform = VulkanPlatform.xcb;
        // if (name == "VK_KHR_xlib_surface") *vulkanPlatform = VulkanPlatform.xlib;
    }

    return sdlExtensionNames;
}


