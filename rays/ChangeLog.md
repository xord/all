# rays ChangeLog


## [v0.3.4] - 2025-03-07

- Add msys2_mingw_dependencies for openal and glew

- Update glm library
- Painter: no stroke by default
- Passing :no or :none to Painter::set_fill()/set_stroke() is equivalent to calling no_fill()/no_stroke()
- BLEND_REPLACE disables fill/stroke only on calling no_fill/no_stroke (alpha 0 does not mean to no_fill/no_stroke)

- Fix a bug that both fill and stroke were drawn even with blend_mode REPLACE, no_fill, and no_stroke combinations
- Fix problem of not drawing when BLEND_REPLACE is combined with alpha 0


## [v0.3.3] - 2025-01-23

- Add '#version 120' line to shader source
- Add Rays.renderer_info

- Fix shader error on Intel GPU


## [v0.3.2] - 2025-01-14

- Update workflow files
- Set minumum version for runtime dependency


## [v0.3.1] - 2025-01-13

- Update LICENSE
- Add smooth flag for Image


## [v0.3] - 2024-07-06

- Support Windows


## [v0.2.1] - 2024-07-05

- Add OpenGL_init() and OpenGL_fin()
- Add activate_offscreen_context()
- Do not redefine fin!() methods, they are no longer needed
- Update workflows for test
- Update to actions/checkout@v4


## [v0.2] - 2024-03-14

- Change the super class for exception class from RuntimeError to StandardError
- Fix compile errors on iOS


## [v0.1.49] - 2024-02-07

- Add point(), line_height(), and line_height!() to Painter
- Add translate!(), scale!(), rotate!(), transpose(), and transpose!() to Rays::Matrix class
- Add ortho(), perspective(), and look_at() to Rays::Matrix
- Add Color#to_hsv
- Add get_hsv()
- hsb as an alias for hsv

- Font::get_width() handles multiple lines if there is a newline character
- Painter::curve() and Painter::bezier() use nsegment state
- Polygon.curve() and Polygon.bezier() can take 'nsegment' parameter
- When updating a texture with a bitmap, the texture is reused, not created anew
- If the texture is bound to the frame buffer, replacing it with a new texture will cause the drawing target to shift
- Set the modified flag on the texture in the framebuffer at the beginning of painting
- Set modified flag for bitmap if needed
- Throw error on conflict between bitmap and texture

- Fix a bug that dust was drawn on the right edge when drawing text
- Fix that Painter#point ignores stroke_cap
- Fix Matrix::to_a order


## [v0.1.48] - 2024-01-08

- Add Bitmap#pixels=
- Add Font#dup, Font#size=, Font.families, and Font.load
- Add Polyline#with
- Add Painter#texture, Painter#texcoord_mode,  and Painter#texcoord_wrap

- Delete Polygon::Line because it was merged into Polyline

- Polygon and Polyline can take colors and texcoords for each vertex
- Polyline.new can take 'hole' parameter
- 'polygonA + polygonB' means Polygon.new(*polygonA.to_a, *polygonB.to_a)
- Polygon with only holes raises an ArgumentError
- Image delegates 'pixels' accessors to Bitmap
- Use GL_CLAMP_TO_EDGE for texturing
- Refine Point#inspect(), Color#inspect(), and Font#inspect()
- default_font() -> get_default_font()
- rays/include/noise.h -> rays/include/util.h

- Fix Polygon.bezier() returns broken object
- Fix get_pixels() does not work with float colors


## [v0.1.47] - 2023-12-09

- Add Polygon's singleton methods: points(), lines(), triangles(), triangle_strip(), triangle_fan(), quads(), quad_strip()
- Add create_polygon(DrawMode, ...)
- Add Painter#stroke_outset
- Add Bitmap#pixels
- Use earcut.hpp for polygon triangulation and delete poly2tri
- Painter#polygon() can take x, y, width, and height
- Polygon#bounds() caches bounds
- Polygon.line() -> Polygon.line_strip()
- Rays::Polygon.new() can take DrawMode
- Matrix(nullptr) avoids initialization
- Trigger github actions on all pull_request


## [v0.1.46] - 2023-11-09

- Use Gemfile to install gems for development instead of add_development_dependency in gemspec
- empty -> is_empty


## [v0.1.45] - 2023-10-29

- Fixed Image class to clear the update flag only when one of the bitmap and texture is being updated


## [v0.1.44] - 2023-10-25

- Add '#include <assert.h>' to Fix compile errors


## [v0.1.43] - 2023-06-22

- Image.new can take pixel density with decimal point


## [v0.1.42] - 2023-06-11

- Point#normal() checks 'length == 0' again


## [v0.1.41] - 2023-06-08

- Point#normal() does not check 'length == 0'


## [v0.1.40] - 2023-06-07

- Redesign parameters for Bitmap#[]=


## [v0.1.39] - 2023-05-29

- Add Painter#painting?


## [v0.1.38] - 2023-05-27

- required_ruby_version >= 3.0.0
- Add spec.license


## [v0.1.37] - 2023-05-18

- Update dependencies


## [v0.1.36] - 2023-05-11

- Fix a few minor problems


## [v0.1.35] - 2023-05-08

- Update dependencies


## [v0.1.34] - 2023-04-30

- Test Image#size


## [v0.1.33] - 2023-04-22

- Update external libraries
- Save_image(image, path) -> Image::save(path)


## [v0.1.32] - 2023-03-01

- Fix bugs


## [v0.1.31] - 2023-02-27

- Add ChangeLog.md file
- Add test.yml, tag.yaml, and release.yml
- Requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- Default precision: mediump -> highp
- Do not use buffer object to draw on iOS
- Fix conflicting rays's Init_exception() and others Init_exception()
- Disable non-power-of-two texture by default
- Restore premultiplied rgb values of the font texture on iOS
- Fix buffer leak
- Fix compile errors on building for iOS
- Refactoring
