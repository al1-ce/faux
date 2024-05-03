// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.vk.pipeline;

import std.string: toStringz, fromStringz;
import std.file: read;

import faux.vk.lib;

import faux.vk.context;
import faux.vk.vertex;

import faux.log;

void createShaderModule(VkContext vk, VkShaderModule* shaderModule, void[] code) {
    VkShaderModuleCreateInfo createInfo;

    createInfo.codeSize = code.length;
    createInfo.pCode = cast(uint*) code.ptr;

    VkResult result = vkCreateShaderModule(vk.device, &createInfo, null, shaderModule);
    if (result != VK_SUCCESS) {
        error("Failed to creeate shader module - ", result);
    }
}

void createGraphicsPipeline(ref VkContext vk) {
    VkShaderModule vertShaderModule;
    VkShaderModule fragShaderModule;
    createShaderModule(vk, &vertShaderModule, read("res/spiv/triangle.vert.spv"));
    createShaderModule(vk, &fragShaderModule, read("res/spiv/triangle.frag.spv"));

    // ooooowweeeee now that's a treat. this will allow to set entry point
    // meaning user can have code with multiple entrypoints
    // Also on another note, since we pre-process it all it can have
    // some custom names and stuff
    VkPipelineShaderStageCreateInfo vertShaderStageInfo;
    vertShaderStageInfo.stage = VK_SHADER_STAGE_VERTEX_BIT;
    vertShaderStageInfo.module_ = vertShaderModule;
    vertShaderStageInfo.pName = "main";
    vertShaderStageInfo.pSpecializationInfo = null; // allows to set constants

    VkPipelineShaderStageCreateInfo fragShaderStageInfo;
    fragShaderStageInfo.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    fragShaderStageInfo.module_ = fragShaderModule;
    fragShaderStageInfo.pName = "main";
    fragShaderStageInfo.pSpecializationInfo = null; // allows to set constants

    VkPipelineShaderStageCreateInfo[] shaderStages = [
        vertShaderStageInfo, fragShaderStageInfo
    ];

    VkDynamicState[] dynamicStates = [
        VK_DYNAMIC_STATE_VIEWPORT,
        VK_DYNAMIC_STATE_SCISSOR
    ];

    VkPipelineDynamicStateCreateInfo dynamicState;
    dynamicState.dynamicStateCount = cast(uint) dynamicStates.length;
    dynamicState.pDynamicStates = dynamicStates.ptr;

    VkPipelineVertexInputStateCreateInfo vertexInputInfo;
    vertexInputInfo.vertexBindingDescriptionCount = 1;
    VkVertexInputBindingDescription bindingDescription = Vertex.getBindingDescription();
    vertexInputInfo.pVertexBindingDescriptions = &bindingDescription;
    vertexInputInfo.vertexAttributeDescriptionCount = Vertex.getAttributeDescriptions().length;
    vertexInputInfo.pVertexAttributeDescriptions = Vertex.getAttributeDescriptions().ptr;

    VkPipelineInputAssemblyStateCreateInfo inputAssembly;
    // inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
    inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    inputAssembly.primitiveRestartEnable = VK_FALSE;

    VkViewport viewport;
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = cast(float) vk.swapChainExtent.width;
    viewport.height = cast(float) vk.swapChainExtent.height;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;

    VkRect2D scissor;
    scissor.offset = VkOffset2D(0, 0);
    scissor.extent = vk.swapChainExtent;

    VkPipelineViewportStateCreateInfo viewportState;
    viewportState.viewportCount = 1;
    viewportState.pViewports = &viewport;
    viewportState.scissorCount = 1;
    viewportState.pScissors = &scissor;

    VkPipelineRasterizationStateCreateInfo rasterizer;
    rasterizer.depthClampEnable = VK_FALSE;
    rasterizer.rasterizerDiscardEnable = VK_FALSE;
    rasterizer.polygonMode = VK_POLYGON_MODE_FILL; // Set MODE_LINE for lines
    rasterizer.lineWidth = 1.0f;
    rasterizer.cullMode = VK_CULL_MODE_BACK_BIT;
    rasterizer.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    // rasterizer.frontFace = VK_FRONT_FACE_CLOCKWISE;
    rasterizer.depthBiasEnable = VK_FALSE;
    rasterizer.depthBiasConstantFactor = 0.0f;
    rasterizer.depthBiasClamp = 0.0f;
    rasterizer.depthBiasSlopeFactor = 0.0f;

    // debug things
    // rasterizer.polygonMode = VK_POLYGON_MODE_LINE;
    // rasterizer.cullMode = VK_CULL_MODE_NONE;

    VkPipelineMultisampleStateCreateInfo multisampling;
    multisampling.sampleShadingEnable = VK_TRUE;
    multisampling.rasterizationSamples = vk.msaaSamples;
    multisampling.minSampleShading = 0.2f;
    multisampling.pSampleMask = null;
    multisampling.alphaToCoverageEnable = VK_FALSE;
    multisampling.alphaToOneEnable = VK_FALSE;

    // Depth and stencil testing - null for now

    VkPipelineColorBlendAttachmentState colorBlendAttachment;
    colorBlendAttachment.colorWriteMask =
        VK_COLOR_COMPONENT_R_BIT |
        VK_COLOR_COMPONENT_G_BIT |
        VK_COLOR_COMPONENT_B_BIT |
        VK_COLOR_COMPONENT_A_BIT;
    // Tweak to simulate GL_BLEND_***
    colorBlendAttachment.blendEnable = VK_FALSE;
    colorBlendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_ONE;
    colorBlendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ZERO;
    colorBlendAttachment.colorBlendOp = VK_BLEND_OP_ADD;
    colorBlendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    colorBlendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
    colorBlendAttachment.alphaBlendOp = VK_BLEND_OP_ADD;

    VkPipelineColorBlendStateCreateInfo colorBlending;
    colorBlending.logicOpEnable = VK_FALSE;
    colorBlending.logicOp = VK_LOGIC_OP_COPY;
    colorBlending.attachmentCount = 1;
    colorBlending.pAttachments = &colorBlendAttachment;
    colorBlending.blendConstants[0] = 0.0f;
    colorBlending.blendConstants[1] = 0.0f;
    colorBlending.blendConstants[2] = 0.0f;
    colorBlending.blendConstants[3] = 0.0f;

    VkPipelineLayoutCreateInfo pipelineLayoutInfo;
    pipelineLayoutInfo.setLayoutCount = 1;
    pipelineLayoutInfo.pSetLayouts = &(vk.descriptorSetLayout);
    pipelineLayoutInfo.pushConstantRangeCount = 0;
    pipelineLayoutInfo.pPushConstantRanges = null;

    VkPipelineLayout pipelineLayout;
    VkResult result = vkCreatePipelineLayout(vk.device, &pipelineLayoutInfo, null, &pipelineLayout);
    if (result != VK_SUCCESS) {
        error("Failed to create pipeline layout - ", result);
    }
    vk.pipelineLayout = pipelineLayout;
    info("Successfully created pipeline layout");

    VkPipelineDepthStencilStateCreateInfo depthStencil;
    depthStencil.depthTestEnable = VK_TRUE;
    depthStencil.depthWriteEnable = VK_TRUE;
    depthStencil.depthCompareOp = VK_COMPARE_OP_LESS;
    depthStencil.depthBoundsTestEnable = VK_FALSE;
    depthStencil.minDepthBounds = 0.0f;
    depthStencil.maxDepthBounds = 1.0f;
    depthStencil.stencilTestEnable = VK_FALSE;

    VkGraphicsPipelineCreateInfo pipelineInfo;
    pipelineInfo.stageCount = 2;
    pipelineInfo.pStages = shaderStages.ptr;
    pipelineInfo.pVertexInputState = &vertexInputInfo;
    pipelineInfo.pInputAssemblyState = &inputAssembly;
    pipelineInfo.pViewportState = &viewportState;
    pipelineInfo.pRasterizationState = &rasterizer;
    pipelineInfo.pMultisampleState = &multisampling;
    pipelineInfo.pDepthStencilState = null;
    pipelineInfo.pColorBlendState = &colorBlending;
    pipelineInfo.pDynamicState = &dynamicState;
    pipelineInfo.pDepthStencilState = &depthStencil;
    pipelineInfo.layout = vk.pipelineLayout;
    pipelineInfo.renderPass = vk.renderPass;
    pipelineInfo.subpass = 0;
    pipelineInfo.basePipelineHandle = VK_NULL_HANDLE;
    pipelineInfo.basePipelineIndex = -1;

    VkPipeline graphicsPipeline;
    result = vkCreateGraphicsPipelines(vk.device, VK_NULL_HANDLE, 1, &pipelineInfo, null, &graphicsPipeline);
    if (result != VK_SUCCESS) {
        error("Failed to create graphics pipeline - ", result);
    }
    vk.graphicsPipeline = graphicsPipeline;

    vkDestroyShaderModule(vk.device, vertShaderModule, null);
    vkDestroyShaderModule(vk.device, fragShaderModule, null);

    info("Successfully created graphics pipeline");
}
