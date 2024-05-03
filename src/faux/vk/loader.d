// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.loader;

import erupted;
import erupted.vulkan_lib_loader;

import faux.log;

/// Loads initial Erupted symbols
void loadLibraryVulkan() {
    bool vulkanLoaded = loadGlobalLevelFunctions();

    // Have to load manually
    if (!vulkanLoaded) {
        // vkGetInstanceProcAddr()
        fatal("Erupted (Vulkan) library failed to load");
        // TODO: figure out how to get error
    }
    info("Erupted (Vulkan) library loaded");
}

/++
Loads instance-level symbols

Must be ran as soon as instance is created
+/
void loadLibraryVulkanInstance(VkInstance instance) {
    loadInstanceLevelFunctions(instance);
}

