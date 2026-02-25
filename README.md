# **FNF 2P's Modding Engine**

**(Based on Psych Engine 0.6.3)**

---

## **2P Engine Lua++**

### **Video Sprite Lua Functions**

> Warning
> 
> - Playing videos on `camGame` can cause severe lag.
> - Video audio follows the global volume and mute settings. Each video also has its own relative volume.
> - Videos are automatically cleaned up after playback ends to prevent memory leaks.

---

### **Preload (Cache) Video**

Pre-caches a video reference for later use.

It’s best to call this function **inside `onCreatePost()`**.

Note: this function does **not** start decoding/playing the video. If you want the video to be fully ready to show instantly, create it early with `makeVideo(..., true)` (paused + hidden) and then `resumeVideo()` when needed.

```lua
precacheVideo('videoName', 'videoTag')
```

### **Create and Play Video**

Creates a video sprite, resizes it to fit the screen, and (by default) starts playing.

**Optional:** `pauseOnReady` (default `false`)
- If `true`: the video will be created **paused** and **hidden** (alpha 0) once it becomes ready.
- If `false`: the video will play immediately.

```lua
makeVideo('videoName', 'videoTag', 'camHUD')

-- Create early but keep hidden + paused (good for mid-song cutscenes)
makeVideo('videoName', 'videoTag', 'camOther', true)
```

### **Set Video Position**

```lua
setPositionVideo('videoTag', x, y)
```

### **Set Video Scale**

```lua
scaleVideo('videoTag', scaleX, scaleY)
```

---

### **Pause Video**

```lua
pauseVideo('videoTag')
```

### **Resume Paused Video**

Resumes playback and makes the video visible (sets alpha to `1`).

```lua
resumeVideo('videoTag')
```

### **Stop and Delete Video**

Stops playback and removes the video sprite.

```lua
stopVideo('videoTag')
```

### **Tween Video Alpha**

Gradually changes the video’s transparency.

**Order:** `(tweenTag, videoTag, alpha, time, ease)`

```lua
tweenAlphaVideo('TweenTag', 'videoTag', 0.5, 1.0, 'linear')
```

### **Set Video Alpha Instantly**

```lua
setAlphaVideo('videoTag', 1.0)
```

### **Set Video Volume**

Sets the relative volume for a specific video (0.0 ~ 1.0).

Final output = Global volume × Video volume, and respects the global mute setting.

```lua
setVideoVolume('videoTag', 0.8)
```

---

## **Windows Functions**

### **Change Windows Wallpaper**

If `absolute` is `false`, the image will be loaded from `mods/images`.

**Order:** `(pngPath, absolute)`

```lua
changeWallpaper('funkay', false)
```
