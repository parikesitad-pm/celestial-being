// GN particles: when the cursor jumps (new prompt, a jump across the screen), it leaves a short
// drift of green GN-drive dust along its path. Plain typing stays below the jump threshold on
// purpose: motion on every keystroke gets tiring fast.
const float DURATION = 0.32;
const vec3 GN_GREEN = vec3(0.180, 0.902, 0.659);   // #2ee6a8, the shell accent
const float SPECKS = 14.0;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float age = iTime - iTimeCursorChange;
    if (iFocus == 0 || age >= DURATION) return;

    float cell = iCurrentCursor.w;
    vec2 head = iCurrentCursor.xy + vec2(iCurrentCursor.z, -cell) * 0.5;
    vec2 origin = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;
    vec2 jump = head - origin;
    if (dot(jump, jump) < 4.0 * cell * cell) return;

    float p = age / DURATION;
    float glow = 0.0;
    for (float i = 0.0; i < SPECKS; i += 1.0) {
        // Each speck sits somewhere on the path and drifts sideways a little as it fades.
        float t = hash(i * 7.13 + iTimeCursorChange);
        vec2 side = normalize(vec2(-jump.y, jump.x) + 1e-4);
        vec2 pos = mix(origin, head, t) + side * (hash(i * 3.71) - 0.5) * cell * (0.6 + 1.6 * p);
        float r = cell * (0.10 + 0.08 * hash(i * 1.93)) * (1.0 - p);
        glow += smoothstep(r, 0.0, length(fragCoord - pos)) * (1.0 - t * 0.5);
    }
    // A brighter ember at the cursor's new spot.
    glow += smoothstep(cell * 0.45 * (1.0 - p), 0.0, length(fragCoord - head)) * 0.8;

    fragColor.rgb = mix(fragColor.rgb, GN_GREEN, clamp(glow, 0.0, 1.0) * (1.0 - p));
}
