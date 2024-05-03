// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.context;

// import bindbc.sdl: SDL_Window;

import faux.vk.lib;

// import vulkan.vertex;

struct VkContext {
    deprecated
    float                    startTime;

    deprecated
    VkInstance               instance;

    deprecated
    VkDebugUtilsMessengerEXT debugMessenger;

    VkPhysicalDevice         physicalDevice;
    VkDevice                 device;

    deprecated
    VkSurfaceKHR             surface;
    // TODO: own surface with own pipelines

    VkQueue                  graphicsQueue;
    VkQueue                  presentQueue;

    VkSwapchainKHR           swapChain;
    VkImage[]                swapChainImages;
    VkImageView[]            swapChainImageViews;
    VkFormat                 swapChainImageFormat;
    VkExtent2D               swapChainExtent;
    VkFramebuffer[]          swapChainFramebuffers;

    VkRenderPass             renderPass;
    VkDescriptorSetLayout    descriptorSetLayout;
    VkPipelineLayout         pipelineLayout;
    VkPipeline               graphicsPipeline;

    VkCommandPool            commandPool;
    VkCommandBuffer[]        commandBuffers;

    // Vertex[]                 vertices;
    // uint[]                   indices;

    VkBuffer                 vertexBuffer;
    VkDeviceMemory           vertexBufferMemory;
    VkBuffer                 indexBuffer;
    VkDeviceMemory           indexBufferMemory;

    VkBuffer[]               uniformBuffers;
    VkDeviceMemory[]         uniformBuffersMemory;
    void*[]                  uniformBuffersMapped;

    VkDescriptorPool         descriptorPool;
    VkDescriptorSet[]        descriptorSets;

    uint                     mipLevels = 1;
    VkImage                  textureImage;
    VkDeviceMemory           textureImageMemory;
    VkImageView              textureImageView;
    VkSampler                textureSampler;

    VkImage                  depthImage;
    VkDeviceMemory           depthImageMemory;
    VkImageView              depthImageView;

    VkImage                  colorImage;
    VkDeviceMemory           colorImageMemory;
    VkImageView              colorImageView;

    VkSemaphore[]            imageAvailableSemaphores;
    VkSemaphore[]            renderFinishedSemaphores;
    VkFence[]                inFlightFences;

    uint framesInFlight      = 2;
    uint currentFrame        = 0;
    uint vertexSize          = 0;
    uint indexSize           = 0;
    bool framebufferResized  = false;

    VkSampleCountFlagBits msaaSamples = VK_SAMPLE_COUNT_1_BIT;

    string modelPath = "res/models/medkit.obj";
    string texturePath = "res/models/medkit_albedo.png";

    debug { const bool isDebug = true;  }
    else  { const bool isDebug = false; }
}


