# Federation Classic concept-fidelity candidate v7

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate awaiting explicit maintainer visual approval**. Passing
tests and similarity checks do not grant approval.

V7 addresses the maintainer's rejection of v6:

- LCARS raster rails now contribute only their nine-slice alpha silhouette;
  their source luminance can no longer create a shaded overlay in the flat
  lilac, amber, and salmon panels.
- The concept proof uses the shared production progress-wheel painter, with
  the concept's scheduled/unscheduled proportions and Classic semantic colors.
- The command crown uses the maintainer-supplied Axion delta-and-orbit mark
  with both `AXION` and `CLINICAL CALENDAR` text removed.

The equal-size landscape comparison uses the approved #113 concept as the
independent normative source. The runtime capture mounts the production
Federation Classic shell and Calendar renderer with representative fictional
slot fixtures. Separate application integration tests mount the real Calendar,
Planning, PlacementDock, progress, Attention, and primary Planning action.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production-shell capture.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: intentional portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale proof.

Renderer contract: `federation-classic-owned-responsive-console-v7`.

The automated ratchet isolates theme-owned chassis from live bay content.
V7 scores 0.9080 crown IoU, 0.9846 left-rail IoU, 0.9700 right-rail IoU,
0.7602 navigation IoU, and 0.9142 progress-wheel IoU. Every isolated chassis
boundary exceeds the 0.80 F1 floor. Crown material banding is 0.0000 versus
0.0041 in the concept. These checks prevent regression but cannot replace
maintainer review.

## Axion delta edit record

Mode: built-in image-generation `precise-object-edit`, followed by chroma-key
removal. Prompt:

> Preserve the upper silver Axion delta-and-orbit emblem exactly; remove the
> entire AXION wordmark and gray background; keep only the centered polished
> silver emblem on a flat chroma-key field. No text, letters, added icons,
> watermark, shadow, crop, redesign, rotation, or material change.

Production asset:
`assets/federation_classic_raster/axion-delta-v1.png` (1115 by 1410,
transparent corners, no text), SHA-256
`78e758d0ea67e14be15ba63c22ba9510147d4bfa6dc9c696df43fa66a2346c1b`.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
386a2aab2c03694a9f9e1afe18ab845ab2b17ca06fd86624e91798557645d710  landscape-concept-vs-runtime.png
2fac1f329519d548b36efdf2e0977626a4047a2f7e419507d3dffb27e84894d4  runtime-landscape-1586x992.png
94786fe61585b11fccac7aee17a24335ef3f4bbfb9213702f20e1e1e875ce4bc  runtime-portrait-200-percent-900x1440.png
c2426211459a35f8e0a70b959b45ceb032929cdb7cac412fda7e0a23fca0cb2e  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
