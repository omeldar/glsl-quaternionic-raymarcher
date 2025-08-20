// shader.wgsl
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

// Uniforms are passed in a special struct.
// This struct defines the data we'll send from JavaScript.
struct Uniforms {
    resolution: vec2<f32>,
    time: f32,
    mouse: vec2<f32>,
};

// Bind the uniform struct to a specific location that JavaScript can talk to.
// @group(0) @binding(0) means it's the first resource in the first group.
@group(0) @binding(0) var<uniform> u: Uniforms;

// The vertex shader's job is to position the vertices.
// For a full-screen effect, we generate the vertices for two triangles
// that cover the screen directly in the shader.
@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
    // An array holding the 6 vertices of our two triangles.
    let pos = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0), // Triangle 1, Vertex 1
        vec2<f32>(1.0, -1.0), // Triangle 1, Vertex 2
        vec2<f32>(-1.0, 1.0), // Triangle 1, Vertex 3
        vec2<f32>(-1.0, 1.0), // Triangle 2, Vertex 1
        vec2<f32>(1.0, -1.0), // Triangle 2, Vertex 2
        vec2<f32>(1.0, 1.0)  // Triangle 2, Vertex 3
    );

    // Return the correct vertex position based on the vertex index.
    return vec4<f32>(pos[in_vertex_index], 0.0, 1.0);
}

// The fragment shader runs for every single pixel on the screen.
@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    // Calculate UV coordinates, normalizing the pixel's position to a [0, 1] range.
    let uv = frag_coord.xy / u.resolution.xy;
    
    // Create a simple color based on time and the UV coordinates.
    // This is the part you'll replace with your creative fractal logic!
    let color = vec3<f32>(uv.x, uv.y, 0.5 + 0.5 * sin(u.time));

    // Return the final color for the pixel.
    return vec4<f32>(color, 1.0);
}
