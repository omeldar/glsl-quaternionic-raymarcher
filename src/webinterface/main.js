// main.js
//
// Copyright (C) 2025 Eldar Omerovic
// This file is part of wgsl-quaternionic-raymarcher.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// --- Global Variables ---
let device;
let context;
let pipeline;
let uniformBuffer;
let uniformBindGroup;
let canvas;
const mousePosition = { x: 0.5, y: 0.5 };

// --- Main execution starts here ---
// The main function is 'async' to allow for 'await'ing the shader file.
async function main() {
    // 1. Initialize WebGPU
    if (!navigator.gpu) {
        alert("WebGPU is not supported by your browser or may not be enabled.");
        return;
    }
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) {
        alert("Failed to get GPU adapter.");
        return;
    }
    device = await adapter.requestDevice();

    // 2. Configure the canvas
    canvas = document.getElementById('gpuCanvas');
    context = canvas.getContext('webgpu');
    const presentationFormat = navigator.gpu.getPreferredCanvasFormat();
    context.configure({
        device,
        format: presentationFormat,
        alphaMode: 'premultiplied',
    });

    // 3. --- FETCH THE SHADER CODE ---
    // Use fetch API to load the text content of shader file.
    const response = await fetch('shader/shader.wgsl');
    const shaderCode = await response.text();
    // --- END OF FETCH LOGIC ---

    const shaderModule = device.createShaderModule({ code: shaderCode });

    // 4. Create the Render Pipeline
    pipeline = device.createRenderPipeline({
        layout: 'auto',
        vertex: {
            module: shaderModule,
            entryPoint: 'vs_main',
        },
        fragment: {
            module: shaderModule,
            entryPoint: 'fs_main',
            targets: [{ format: presentationFormat }],
        },
        primitive: {
            topology: 'triangle-list',
        },
    });

    // 5. Create Buffers
    const uniformBufferSize = (2 + 1 + 1 + 2) * 4; // resolution + time + padding + mouse
    uniformBuffer = device.createBuffer({
        size: uniformBufferSize,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    // 6. Create a Bind Group
    uniformBindGroup = device.createBindGroup({
        layout: pipeline.getBindGroupLayout(0),
        entries: [{
            binding: 0,
            resource: { buffer: uniformBuffer },
        }],
    });
    
    // 7. Add event listeners
    canvas.addEventListener('mousemove', (event) => {
        mousePosition.x = event.clientX / canvas.clientWidth;
        mousePosition.y = 1.0 - (event.clientY / canvas.clientHeight); // Invert Y
    });

    // 8. Start the render loop
    requestAnimationFrame(render);
}

// --- The Render Loop (Unchanged) ---
function render(time) {
    time *= 0.001; // convert to seconds

    const displayWidth = canvas.clientWidth;
    const displayHeight = canvas.clientHeight;
    if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
        canvas.width = displayWidth;
        canvas.height = displayHeight;
    }

    const uniformData = new Float32Array([
        canvas.width, canvas.height,
        time, 0,
        mousePosition.x, mousePosition.y
    ]);
    device.queue.writeBuffer(uniformBuffer, 0, uniformData);

    const commandEncoder = device.createCommandEncoder();
    const textureView = context.getCurrentTexture().createView();

    const renderPassDescriptor = {
        colorAttachments: [{
            view: textureView,
            clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
            loadOp: 'clear',
            storeOp: 'store',
        }],
    };
    const passEncoder = commandEncoder.beginRenderPass(renderPassDescriptor);
    
    passEncoder.setPipeline(pipeline);
    passEncoder.setBindGroup(0, uniformBindGroup);
    passEncoder.draw(6, 1, 0, 0);
    passEncoder.end();

    device.queue.submit([commandEncoder.finish()]);

    requestAnimationFrame(render);
}

// Start the application
main();
