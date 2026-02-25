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

Preloads a video before playback.

Recommended for **mid-song cutscenes or transitions** to reduce lag.

It’s best to call this function **inside `onCreatePost()`** so the video is ready when needed.

```lua
precacheVideo('videoName', 'videoTag')
```

### **Create and Play Video**

Automatically plays and resizes the video to fit the screen.

```lua
makeVideo('videoName', 'videoTag', 'camHUD')
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

**Order:** `(tweenTag, videoTag, startAlpha, endAlpha, tweenType)`

```lua
tweenAlphaVideo('TweenTag', 'videoTag', 0, 0.5, 'linear')
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
