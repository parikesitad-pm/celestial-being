// Exhaust streak behind the cursor when it jumps. Typing moves are below the
// jump threshold on purpose: motion on every keystroke would get tiring fast.
const float DURATION = 0.15;

float segmentDistance(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 1.0), 0.0, 1.0);
    return length(p - a - ab * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float age = iTime - iTimeCursorChange;
    if (iFocus == 0 || age >= DURATION) return;

    float cellHeight = iCurrentCursor.w;
    vec2 halfCell = vec2(iCurrentCursor.z, -cellHeight) * 0.5;
    vec2 head = iCurrentCursor.xy + halfCell;
    vec2 origin = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;

    vec2 jump = head - origin;
    if (dot(jump, jump) < 4.0 * cellHeight * cellHeight) return;

    float p = age / DURATION;
    float eased = 1.0 - pow(1.0 - p, 3.0);
    vec2 tail = mix(origin, head, eased);

    float radius = cellHeight * 0.28 * (1.0 - p);
    float d = segmentDistance(fragCoord, tail, head);
    float streak = smoothstep(radius, radius * 0.25, d) * (1.0 - p);
    fragColor.rgb = mix(fragColor.rgb, iCursorColor, streak * 0.7);
}
