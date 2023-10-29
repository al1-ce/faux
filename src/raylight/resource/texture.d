module raylight.resource.texture;

import std.stdio: writefln;
import std.algorithm: canFind, max;
import std.conv: to;
import std.array: split, join;
import std.range: dropBack;
import std.string: toStringz;

import raylight.lib.opengl.opengl;
import raylight.lib.sdl.sdl;

import sily.vector: vec2;
import sily.color: Color;
import sily.path: fixPath, listdir;

import raylight.core.fs;

struct Texture {
    private uint _id;
    private uint _w;
    private uint _h;

    private bool _doUseMipmaps = false;

    private static string _defaultPath = "res/textures/default.png";

    private TextureType _textureType = TextureType.texture2D;

    this(TextureType type) {
        _textureType = type;
        glGenTextures(1, &_id);
    }

    this(string path) {
        glGenTextures(1, &_id);
        loadFile(path);
    }

    this(string path, TextureType type) {
        _textureType = type;
        glGenTextures(1, &_id);
        if (type == TextureType.cubeMap) {
            writefln("Use loadCubemap function instead of default constructor for '%s'.", path);
        }
        loadFile(path);
    }

    // TODO probably change to texture array
    /**
     *
     * Params:
     *   folderPath = Path to folder relative to app root folder (not bin)
     *   size = Atlas width and height
     *   clampSize = Fake border size. Used to remove seams on texture edges
     * Returns: `TextureRegion[]` of loaded textures `TextureRegion(w, h, u, v, name)`
     */
    TextureRegion[string] loadAtlas(string folderPath, uint size, int clampSize) {
        SDL_Surface* atlas = SDL_CreateRGBSurface(0, size, size, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
        TextureRegion[string] regions;

        SDL_UnlockSurface(atlas);

        int yoff = 0;
        int xoff = 0;
        int ymax = 0;
        // float margin = max(1.0f / size, 0.01f);

        float texelCorrection = 0.01f / size;

        string path = folderPath.fixPath;
        string[] files = listdir(path);
        foreach (file; files) {
            if (!file.canFind(".png")) continue;
            string filepath = path ~ "\\" ~ file;
            SDL_Surface* img = loadSurface(filepath);
            SDL_UnlockSurface(img);
            // SDL_LockSurface(img);
            if (yoff + img.h + clampSize * 2 > size) {
                writefln("TEX::ERROR Atlas size for '%s' is too small. ", path); break;}
            if (xoff + img.w + clampSize * 2 > size) {
                xoff = 0; yoff += ymax + clampSize * 2; ymax = 0; } else { ymax = ymax.max(img.h); }

            float u = ((xoff.to!float + clampSize) / size.to!float) + texelCorrection;
            float v = ((yoff.to!float + clampSize) / size.to!float) + texelCorrection;
            float uvw = (img.w.to!float / size.to!float) - texelCorrection;
            float uvh = (img.h.to!float / size.to!float) - texelCorrection;

            string texname = file.split(".").dropBack(1).join(".");
            regions[texname] = TextureRegion( img.w, img.h, u, v, uvw, uvh, texname );

            // SDL_Rect irct;
            // irct.x = 0;
            // irct.y = 0;
            // irct.w = img.w;
            // irct.h = img.h;
            // SDL_Rect rect; // pos of img paste
            // rect.x = xoff;
            // rect.y = yoff; // size - img.h - yoff; // flipped Y (do not, its opengl)
            // rect.w = img.w;
            // rect.h = img.h;
            // SDL_BlitSurface(img, &irct, atlas, &rect);
            if (clampSize > 0) {
                blitSurfaceScaled(img, Rect(0, 0, 1, img.h), atlas,
                    Rect(xoff, yoff + clampSize, clampSize, img.h)); // copy left edge

                blitSurfaceScaled(img, Rect(img.w - 1, 0, 1, img.h), atlas,
                    Rect(xoff + img.w + clampSize, yoff + clampSize, clampSize, img.h)); // right edge

                blitSurfaceScaled(img, Rect(0, 0, img.w, 1), atlas,
                    Rect(xoff + clampSize, yoff, img.w, clampSize)); // top edge

                blitSurfaceScaled(img, Rect(0, img.h - 1, img.w, 1), atlas,
                    Rect(xoff + clampSize, yoff + img.h + clampSize, img.w, clampSize)); // bottom edge


                blitSurfaceScaled(img, Rect(0, 0, 1, 1), atlas,
                    Rect(xoff, yoff, clampSize, clampSize)); // copy top left corner

                blitSurfaceScaled(img, Rect(img.w - 1, 0, 1, 1), atlas,
                    Rect(xoff + img.w + clampSize, yoff, clampSize, clampSize)); // copy top right corner

                blitSurfaceScaled(img, Rect(0, img.h - 1, 1, 1), atlas,
                    Rect(xoff, yoff + img.h + clampSize, clampSize, clampSize));  // copy bottom left corner

                blitSurfaceScaled(img, Rect(img.w - 1, img.h - 1, 1, 1), atlas,
                    Rect(xoff + img.w + clampSize, yoff + img.h + clampSize, clampSize, clampSize));  // copy bottom right corner
            }

            blitSurface(img, Rect(0, 0, img.w, img.h), atlas, Rect(xoff + clampSize, yoff + clampSize, img.w, img.h));

            xoff += img.w + clampSize * 2;
            SDL_FreeSurface(img);
        }

        setBitmap(_doUseMipmaps, GL_RGBA, size, size, GL_RGBA, GL_UNSIGNED_BYTE, atlas.pixels);
        _w = size;
        _h = size;
        // SDL_SaveBMP(atlas, (path ~ "\\atlas.bmp").toStringz);
        SDL_FreeSurface(atlas);
        checkErrors();

        return regions;
    }

    /**
     * Copies SDL surface into another SDL surface
     * Params:
     *   s_from = SDL surface to copy from
     *   r_from = Rectangle to copy
     *   s_to = SDL surface to copy into
     *   r_to = Rectangle to copy into
     */
    private void blitSurface(SDL_Surface* s_from, Rect r_from, SDL_Surface* s_to, Rect r_to) {
        SDL_Rect frect;
        frect.x = r_from.x;
        frect.y = r_from.y;
        frect.w = r_from.w;
        frect.h = r_from.h;
        SDL_Rect trect; // pos of img paste
        trect.x = r_to.x;
        trect.y = r_to.y; // size - img.h - yoff; // flipped Y (do not, its opengl)
        trect.w = r_to.w;
        trect.h = r_to.h;
        SDL_BlitSurface(s_from, &frect, s_to, &trect);
    }

    /**
     * Copies SDL surface into another SDL surface
     * Params:
     *   s_from = SDL surface to copy from
     *   r_from = Rectangle to copy
     *   s_to = SDL surface to copy into
     *   r_to = Rectangle to copy into
     */
    private void blitSurfaceScaled(SDL_Surface* s_from, Rect r_from, SDL_Surface* s_to, Rect r_to) {
        SDL_Rect frect;
        frect.x = r_from.x;
        frect.y = r_from.y;
        frect.w = r_from.w;
        frect.h = r_from.h;
        SDL_Rect trect; // pos of img paste
        trect.x = r_to.x;
        trect.y = r_to.y; // size - img.h - yoff; // flipped Y (do not, its opengl)
        trect.w = r_to.w;
        trect.h = r_to.h;
        SDL_BlitScaled(s_from, &frect, s_to, &trect);
    }

    private struct Rect {
        int x, y, w, h;
        this(int _x, int _y, int _w, int _h) {
            x = _x;
            y = _y;
            w = _w;
            h = _h;
        }
    }

    // TextureRegion[] loadAtlas(ubyte[] pixelData, uint size) {
    //     // SDL_CreateRGBSurfaceFrom
    // }

    /**
     * Loads image from `path` into `SDL_Surface`
     * Params:
     *   path = Path to image
     * Returns: Flipped `SDL_Surface`
     */
    SDL_Surface* loadSurface(string path) {
        path = path.fixPath;
        SDL_Surface* img = IMG_Load(path.toStringz);
        if (!img) {
            assert(path != _defaultPath, "Could not load default image");
            writefln("Could not load image at '%s'.\nSDL:IMAGE:ERROR: %s", path, IMG_GetError().to!string);
            // throw new Error("Error loading image.");
            return loadSurface(_defaultPath);
        }
        flipSurface(img);
        SDL_Surface* flippedImg = SDL_ConvertSurfaceFormat(img, SDL_PIXELFORMAT_RGBA32, 0);
        SDL_LockSurface(flippedImg);

        SDL_FreeSurface(img);

        return flippedImg;
    }

    /**
     *
     * Params:
     *   path = Path to face folder
     *   faces = Array of filenames in order: `right, left, top, bottom, front, back`
     */
    void loadCubemap(string path, string[] faces) {
        bind();

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);

        path = path.fixPath;

        for (uint i = 0; i < faces.length; i ++) {
            string p = path ~ "\\" ~ faces[i];
            SDL_Surface* surf = loadSurface(p);
            glTexImage2D(
                GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
                0,
                GL_RGBA.to!int,
                surf.w,
                surf.h,
                0, // legacy
                GL_RGBA,
                GL_UNSIGNED_BYTE,
                surf.pixels);

            SDL_FreeSurface(surf);
        }

        setWrap(GL_REPEAT, GL_REPEAT);
        setFilter(GL_NEAREST, GL_NEAREST);

        unbind();
    }

    /**
     * Loads png surface into current texture
     * Params:
     *   path = Path to image
     */
    void loadFile(string path) {
        SDL_Surface* img = loadSurface(path);

        setBitmap(_doUseMipmaps, GL_RGBA, img.w, img.h, GL_RGBA, GL_UNSIGNED_BYTE, img.pixels);

        _w = img.w;
        _h = img.h;

        SDL_FreeSurface(img);
    }

    /**
     * Sets pixeldata for current texture
     * Params:
     *   genMipmaps = Do generate mipmaps
     *   numComponents = Components (rgba) stored (internal), use `GL_RGBA`
     *   width = Width of texture
     *   height = Height of texture
     *   rgbFormat = Components (rgba) stored, use `GL_RGBA`
     *   dataType = Data array format type
     *   data = Pixel data to bind
     */
    void setBitmap(bool genMipmaps, uint numComponents, uint width, uint height,
                   int rgbFormat, GLenum dataType, GLvoid* data) {
        bind();

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);

        glTexImage2D(
            glType(_textureType),
            0, //mipmapLevel,
            numComponents,
            width,
            height,
            0, // legacy
            rgbFormat,
            dataType,
            data
        );

        setWrap(GL_REPEAT, GL_REPEAT);

        if (genMipmaps) {
            setFilter(GL_NEAREST_MIPMAP_LINEAR, GL_NEAREST); // FIXME mipmaps
            glGenerateMipmap(glType(_textureType));
            glTexParameterf(glType(_textureType), GL_TEXTURE_LOD_BIAS, -1);
        } else {
            setFilter(GL_NEAREST, GL_NEAREST);
        }


        unbind();
    }

    /**
     *
     * Params:
     *   xWrap = Wrapping on X axis
     *   yWrap = Wrapping on Y axis
     *   zWrap = Wrapping on Z axis
     */
    void setWrap(GLenum xWrap, GLenum yWrap, GLenum zWrap = GL_REPEAT) {
        // s, t, r == x, y, z
        bind();
        glTexParameteri(glType(_textureType), GL_TEXTURE_WRAP_S, xWrap);
        glTexParameteri(glType(_textureType), GL_TEXTURE_WRAP_T, yWrap);
        glTexParameteri(glType(_textureType), GL_TEXTURE_WRAP_R, zWrap);
        unbind();
    }

    /**
     *
     * Params:
     *   minFilter = Minifying filter
     *   magFilter = Magnifying filter
     */
    void setFilter(GLenum minFilter, GLenum magFilter) {
        bind();
        glTexParameteri(glType(_textureType), GL_TEXTURE_MIN_FILTER, minFilter);
        glTexParameteri(glType(_textureType), GL_TEXTURE_MAG_FILTER, magFilter);
        unbind();
    }

    /**
     * Sets border color with border wrapping
     * Params:
     *   col = Color to set border
     */
    void setBorderColor(Color col) {
        bind();
        glTexParameterfv(glType(_textureType), GL_TEXTURE_BORDER_COLOR, col.arrayof.ptr);
        unbind();
    }

    /**
     * Binds current texture to GL_TEXTURE0
     */
    void bind() {
        bindTo(GL_TEXTURE0);
    }

    /**
     * Binds current texture to `textureidx`
     * Params:
     *   textureidx = Texture index to bind to
     */
    void bindTo(GLenum textureidx) {
        glActiveTexture(textureidx);
        glBindTexture(glType(_textureType), _id);
    }

    /**
     * Binds current texture to 0
     */
    void unbind() {
        glBindTexture(glType(_textureType), 0);
    }


    /**
     * Binds current texture to 0
     * Params:
     *   type = Type of texture to unbind
     */
    static void unbindType(TextureType type) {
        glBindTexture(glType(type), 0);
    }

    /**
     * Deletes this texture from memory
     */
    void dispose() {
        glDeleteTextures(0, &_id);
    }

    /**
     *
     * Returns: texture at default path
     */
    // static Texture defaultTexture() {
    //     if (_defaultTexture is null) {
    //         _defaultTexture = new Texture("res/textures/default.png");
    //         _defaultTexture.setFilter(GL_NEAREST, GL_NEAREST);
    //         _defaultTexture.setWrap(GL_REPEAT, GL_REPEAT);
    //     }
    //     return _defaultTexture;
    // }

    uint id() {
        return _id;
    }

    uint width() { return _w; }
    uint height() { return _h; }

    /**
     * Flips SDL surface
     * Params:
     *   surface = Surface to flip
     */
    private void flipSurface(SDL_Surface* surface) {
        SDL_LockSurface(surface);

        int pitch = surface.pitch; // row size
        void* temp = (new void[pitch]).ptr; // intermediate buffer
        void* pixels = surface.pixels;

        for(int i = 0; i < surface.h / 2; ++i) {
            // get pointers to the two rows to swap
            void* row1 = pixels + i * pitch;
            void* row2 = pixels + (surface.h - i - 1) * pitch;

            // swap rows
            dmemcpy(temp, row1, pitch);
            dmemcpy(row1, row2, pitch);
            dmemcpy(row2, temp, pitch);
        }

        SDL_UnlockSurface(surface);
    }

    /**
     * Copies array
     * Params:
     *   destination = Pointer to destination array where the content is to be copied
     *   source = Pointer to the source of data to be copied
     *   num = Number of bytes to copy
     * Returns: `destination`
     */
    void * dmemcpy ( void * destination, const void * source, size_t num ) pure nothrow {
        (cast(ubyte*)destination)[0 .. num][]=(cast(const(ubyte)*)source)[0 .. num];
        return destination;
    }

    /**
     * Checks for any SDL errors and logs them if they occur
     */
    void checkErrors() {
        const char *error = SDL_GetError();
        if (*error) {
            SDL_Log("SDL::ERROR %s", error);
            SDL_ClearError();
        }
    }

    /**
     * Wrapping between engine and opengl
     * Params:
     *   type = Texture type
     * Returns: OpenGL TextureType enum
     */
    private static GLenum glType(TextureType type) {
        switch (type) {
            case TextureType.texture2D:
                return GL_TEXTURE_2D;
            case TextureType.cubeMap:
                return GL_TEXTURE_CUBE_MAP;
            default:
                return GL_TEXTURE_2D;
        }
    }

    enum TextureType {
        texture2D, cubeMap
    }
}

struct TextureRegion {
    int w;
    int h;
    float u;
    float v;
    float uvw;
    float uvh;
    string name;
    static TextureRegion defaultRegion = TextureRegion(0, 0, 0, 0, 0, 0, "");
}

//
// import std.string: toStringz;
//
// import raylight.raytype;
// import sily.vector;
// import sily.color;
//
// import rl = raylib;
//
// alias rImage = rl.Image;
// alias rRect = rl.Rectangle;
// alias rFont = rl.Font;
//
// /+
// T *t -> ref T t
// ImageFormat(Image *image) -> ImageFormat(ref rImage image)
//
// ImageAction -> action
// ImageFormat -> format(ref rImage image, int newFormat)
//
// Color -> col
// Rectangle -> vec4
// Vector2 -> vec2
// Vector3 -> vec3
// Vector4 -> vec4
//
// R action(args) {
//     rl.OgFunc(args);
// }
//
// +/
//
// void format(ref rImage img, int newFormat) {
//     rl.ImageFormat(&img, newFormat);
// }
//
// void imageToPOT(ref rImage img, col fill) {
//     rl.ImageToPOT(&img, fill.rayType);
// }
//
// void cropRegion(ref rImage img, vec4 _crop) {
//     rl.ImageCrop(&img, rayType!rRect(_crop));
// }
//
// void cropAlpha(ref rImage img, float threshold) {
//     rl.ImageAlphaCrop(&img, threshold);
// }
//
// void clearAlpha(ref rImage img, col color, float threshold) {
//     rl.ImageAlphaClear(&img, color.rayType, threshold);
// }
//
// void alphaMask(ref rImage img, rImage _alphaMask) {
//     rl.ImageAlphaMask(&img, _alphaMask);
// }
//
// void alphaPremultiply(ref rImage img) {
//     rl.ImageAlphaPremultiply(&img);
// }
//
// void blurGaussian(ref rImage img, int blurSize) {
//     rl.ImageBlurGaussian(&img, blurSize);
// }
//
// void resize(ref rImage img, int newWidth, int newHeight, bool nearest = false) {
//     if (nearest) {
//         rl.ImageResizeNN(&img, newWidth, newHeight);
//     } else {
//         rl.ImageResize(&img, newWidth, newHeight);
//     }
// }
//
// void resize(ref rImage img, int newWidth, int newHeight, int offsetX, int offsetY, col fill) {
//     rl.ImageResizeCanvas(&img, newWidth, newHeight, offsetX, offsetY, fill.rayType);
// }
//
// void generateMipmaps(ref rImage img) {
//     rl.ImageMipmaps(&img);
// }
//
// void dither(ref rImage img, int rBpp, int gBpp, int bBpp, int aBpp) {
//     rl.ImageDither(&img, rBpp, gBpp, bBpp, aBpp);
// }
//
// void flipVertical(ref rImage img) {
//     rl.ImageFlipVertical(&img);
// }
//
// void flipHorizontal(ref rImage img) {
//     rl.ImageFlipHorizontal(&img);
// }
//
// void rotateCW(ref rImage img) {
//     rl.ImageRotateCW(&img);
// }
//
// void rotateCWW(ref rImage img) {
//     rl.ImageRotateCCW(&img);
// }
//
// void tintImage(ref rImage img, col color) {
//     rl.ImageColorTint(&img, color.rayType);
// }
//
// void invertColor(ref rImage img) {
//     rl.ImageColorInvert(&img);
// }
//
// void makeGrayscale(ref rImage img) {
//     rl.ImageColorGrayscale(&img);
// }
//
// void imageContrast(ref rImage img, float contrast) {
//     rl.ImageColorContrast(&img, contrast);
// }
//
// void imageBrightness(ref rImage img, int brightness) {
//     rl.ImageColorBrightness(&img, brightness);
// }
//
// void colorReplace(ref rImage img, col color, col replace) {
//     rl.ImageColorReplace(&img, color.rayType, replace.rayType);
// }
//
// vec4 alphaBorder(rImage img, float threshold) {
//     return rl.GetImageAlphaBorder(img, threshold).rayType;
// }
//
// col imageColor(rImage img, int x, int y) {
//     return rl.GetImageColor(img, x, y).rayType;
// }
//
// void clearBackground(ref rImage dst, col color) {
//     rl.ImageClearBackground(&dst, color.rayType);
// }
//
// void drawPixel(ref rImage dst, int posX, int posY, col color) {
//     rl.ImageDrawPixel(&dst, posX, posY, color.rayType);
// }
//
// void drawPixel(ref rImage dst, vec2 position, col color) {
//     rl.ImageDrawPixelV(&dst, position.rayType, color.rayType);
// }
//
// void drawLine(ref rImage dst, int startPosX, int startPosY, int endPosX, int endPosY, col color) {
//     rl.ImageDrawLine(&dst, startPosX, startPosY, endPosX, endPosY, color.rayType);
// }
//
// void drawLine(ref rImage dst, vec2 start, vec2 end, col color) {
//     rl.ImageDrawLineV(&dst, start.rayType, end.rayType, color.rayType);
// }
//
// void drawCircle(ref rImage dst, int centerX, int centerY, int radius, col color) {
//     rl.ImageDrawCircle(&dst, centerX, centerY, radius, color.rayType);
// }
//
// void drawCircle(ref rImage dst, vec2 center, int radius, col color) {
//     rl.ImageDrawCircleV(&dst, center.rayType, radius, color.rayType);
// }
//
// void drawCircleLines(ref rImage dst, int centerX, int centerY, int radius, col color) {
//     rl.ImageDrawCircleLines(&dst, centerX, centerY, radius, color.rayType);
// }
//
// void drawCircleLines(ref rImage dst, vec2 center, int radius, col color) {
//     rl.ImageDrawCircleLinesV(&dst, center.rayType, radius, color.rayType);
// }
//
// void drawRectangle(ref rImage dst, int posX, int posY, int width, int height, col color) {
//     rl.ImageDrawRectangle(&dst, posX, posY, width, height, color.rayType);
// }
//
// void drawRectangle(ref rImage dst, vec2 position, vec2 size, col color) {
//     rl.ImageDrawRectangleV(&dst, position.rayType, size.rayType, color.rayType);
// }
//
// void drawRectangleRec(ref rImage dst, vec4 rec, col color) {
//     rl.ImageDrawRectangleRec(&dst, rayType!rRect(rec), color.rayType);
// }
//
// void drawRectangleLines(ref rImage dst, vec4 rec, int thick, col color) {
//     rl.ImageDrawRectangleLines(&dst, rayType!rRect(rec), thick, color.rayType);
// }
//
// void drawImage(ref rImage dst, rImage src, vec4 srcRec, vec4 dstRec, col tint) {
//     rl.ImageDraw(&dst, src, rayType!rRect(srcRec), rayType!rRect(dstRec), tint.rayType);
// }
//
// void drawText(ref rImage dst, string text, int posX, int posY, int fontSize, col color) {
//     rl.ImageDrawText(&dst, text.toStringz, posX, posY, fontSize, color.rayType);
// }
//
// void drawText(ref rImage dst, rFont font, string text, vec2 position, float fontSize, float spacing, col tint) {
//     rl.ImageDrawTextEx(&dst, font, text.toStringz, position.rayType, fontSize, spacing, tint.rayType);
// }
//
// import std.file: isDir, exists;
// import std.path: isValidPath, buildNormalizedPath, dirSeparator;
// import std.string: toStringz;
// import std.conv: to;
//
// import raylight.resource.manager;
//
// // loadImage and loadTexture + unload are defined in manager
//
// private string makePath(string path) {
//     return resourcePath ~ dirSeparator ~ path;
// }
//
// rImage loadImageRaw(string filepath, int w, int h, int _format, int headerSize) {
//     if (cached!rImage(filepath)) {
//         return getCache!rImage(filepath);
//     } else {
//         string fp = filepath.makePath;
//         if (!fp.exists) return nopath!rImage(fp);
//         rImage res = rl.LoadImageRaw(fp.toStringz, w, h, _format, headerSize);
//         cache!rImage(filepath, res);
//         return res;
//     }
// }
//
// // Image LoadImageRaw(const char *fileName, int width, int height, int format, int headerSize);       // Load image from RAW file data
// // Image LoadImageAnim(const char *fileName, int *frames);                                            // Load image sequence from file (frames appended to image.data)
// // Image LoadImageFromMemory(const char *fileType, const unsigned char *fileData, int dataSize);      // Load image from memory buffer, fileType refers to extension: i.e. '.png'
// // Image LoadImageFromTexture(Texture2D texture);                                                     // Load image from GPU texture data
// // Image LoadImageFromScreen(void);                                                                   // Load image from screen buffer and (screenshot)
// // bool IsImageReady(Image image);                                                                    // Check if an image is ready
// // void UnloadImage(Image image);                                                                     // Unload image from CPU memory (RAM)
// // bool ExportImage(Image image, const char *fileName);                                               // Export image data to file, returns true on success
// // bool ExportImageAsCode(Image image, const char *fileName);                                         // Export image as code file defining an array of bytes, returns true on success
//
// // // Image manipulation functions
// // Image ImageCopy(Image image);                                                                      // Create an image duplicate (useful for transformations)
// // Image ImageFromImage(Image image, Rectangle rec);                                                  // Create an image from another image piece
// // Image ImageText(const char *text, int fontSize, Color color);                                      // Create an image from text (default font)
// // Image ImageTextEx(Font font, const char *text, float fontSize, float spacing, Color tint);         // Create an image from text (custom sprite font)
//
// // // Image generation functions
// // Image GenImageColor(int width, int height, Color color);                                           // Generate image: plain color
// // Image GenImageGradientV(int width, int height, Color top, Color bottom);                           // Generate image: vertical gradient
// // Image GenImageGradientH(int width, int height, Color left, Color right);                           // Generate image: horizontal gradient
// // Image GenImageGradientRadial(int width, int height, float density, Color inner, Color outer);      // Generate image: radial gradient
// // Image GenImageChecked(int width, int height, int checksX, int checksY, Color col1, Color col2);    // Generate image: checked
// // Image GenImageWhiteNoise(int width, int height, float factor);                                     // Generate image: white noise
// // Image GenImagePerlinNoise(int width, int height, int offsetX, int offsetY, float scale);           // Generate image: perlin noise
// // Image GenImageCellular(int width, int height, int tileSize);                                       // Generate image: cellular algorithm, bigger tileSize means bigger cells
// // Image GenImageText(int width, int height, const char *text);                                       // Generate image: grayscale image from text data
//
// // Texture2D LoadTextureFromImage(Image image);                                                       // Load texture from image data\
//
// // TextureCubemap LoadTextureCubemap(Image image, int layout);                                        // Load cubemap from image, multiple image cubemap layouts supported
// // RenderTexture2D LoadRenderTexture(int width, int height);                                          // Load texture for rendering (framebuffer)
// //
// // // Texture loading functions
// // // NOTE: These functions require GPU access
// // bool IsTextureReady(Texture2D texture);                                                            // Check if a texture is ready
// // bool IsRenderTextureReady(RenderTexture2D target);                                                       // Check if a render texture is ready
// // void UpdateTexture(Texture2D texture, const void *pixels);                                         // Update GPU texture with new data
// // void UpdateTextureRec(Texture2D texture, Rectangle rec, const void *pixels);                       // Update GPU texture rectangle with new data
// //
// // // Texture configuration functions
// // void GenTextureMipmaps(Texture2D *texture);                                                        // Generate GPU mipmaps for a texture
// // void SetTextureFilter(Texture2D texture, int filter);                                              // Set texture scaling filter mode
// // void SetTextureWrap(Texture2D texture, int wrap);                                                  // Set texture wrapping mode
// //
//
// // DO NOT TOUCH END
//
