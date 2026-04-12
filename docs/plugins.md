# VLC 插件平台兼容性表

> 来源：VLC 3.0.23 源码分析 (`vlc-build/modules/`)
> 生成日期：2026-04-12

## 图例

| 符号 | 含义 |
|------|------|
| ✅ | 默认启用 |
| ❌ | 不构建 / 明确禁用 |
| ⚙️ | 条件启用（依赖库检测或平台条件满足时） |
| N/A | 不适用（该平台无此插件，或为平台专用插件） |

---

## ACCESS 模块（访问插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| access_concat | ✅ | ✅ | — |
| access_imem | ✅ | ✅ | — |
| access_mms | ✅ | ✅ | — |
| access_oss | ⚙️ | N/A | HAVE_OSS (Unix) |
| access_realrtsp | ⚙️ | ⚙️ | live555 |
| access_srt | ⚙️ | ⚙️ | srt >= 1.3.0 |
| access_wasapi | N/A | ⚙️ | HAVE_WASAPI |
| avahi | N/A | N/A | Linux only (Zeroconf) |
| avaudiocapture | ⚙️ | N/A | HAVE_AVFOUNDATION |
| avcapture | ⚙️ | N/A | HAVE_AVFOUNDATION |
| avio | ⚙️ | ⚙️ | libavformat, !MERGE_FFMPEG |
| cdda | ✅ | ⚙️ | libcddb |
| dc1394 | ⚙️ | ⚙️ | libdc1394-2 >= 2.1.0 |
| decklink | ⚙️ | ⚙️ | HAVE_DECKLINK |
| directory_demux | ✅ | ✅ | — |
| dshow | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| dsm | ⚙️ | ⚙️ | libdsm |
| dtv | N/A | ⚙️ | DVB support |
| dv1394 | ⚙️ | N/A | libraw1394 |
| dvdnav | ⚙️ | ⚙️ | dvdnav > 4.9.0 |
| dvdread | ⚙️ | ⚙️ | dvdread > 4.9.0 |
| filesystem | ✅ | ✅ | — |
| ftp | ✅ | ✅ | Socket libraries |
| http / https | ✅ | ✅ | Socket + GnuTLS |
| idummy | ✅ | ✅ | — |
| imem | ✅ | ✅ | — |
| libbluray | ⚙️ | ⚙️ | libbluray >= 0.6.2 |
| live555 | ⚙️ | ⚙️ | live555 |
| mtp | ⚙️ | ⚙️ | libmtp >= 1.0.0 |
| nfs | ⚙️ | ⚙️ | libnfs >= 1.10.0 |
| rdp | ⚙️ | ⚙️ | freerdp >= 1.0.1 |
| rist | ⚙️ | ⚙️ | — |
| sftp | ⚙️ | ⚙️ | libssh2 |
| smb | ⚙️ | ⚙️ | smbclient |
| smb2 | ⚙️ | ⚙️ | libsmb2 >= 3.0.0 (disabled by default) |
| srt | ⚙️ | ⚙️ | srt >= 1.3.0 |
| tcp / udp | ✅ | ✅ | Socket libraries |
| v4l2 | N/A | N/A | Linux only |
| vcd | ⚙️ | ⚙️ | — |

---

## AUDIO OUTPUT 模块（音频输出插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| adummy | ✅ | ✅ | — |
| afile | ✅ | ✅ | — |
| alsa | N/A | N/A | Linux only |
| amem | ✅ | ✅ | — |
| auhal | ⚙️ | N/A | HAVE_OSX |
| directsound | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| jack | ⚙️ | ⚙️ | HAVE_JACK |
| mmdevice | N/A | ⚙️ | HAVE_WASAPI, !HAVE_WINSTORE |
| oss | ⚙️ | N/A | HAVE_OSS |
| pulse | ⚙️ | ⚙️ | HAVE_PULSE |
| sndio | N/A | N/A | OpenBSD only |
| wasapi | N/A | ⚙️ | HAVE_WASAPI |
| waveout | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| winstore | N/A | ⚙️ | HAVE_WINSTORE |

---

## VIDEO OUTPUT 模块（视频输出插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| aa | ⚙️ | ❌ | libcaca |
| caca | ⚙️ | ❌ | libcaca >= 0.99.beta14 |
| caopengllayer | ⚙️ | N/A | HAVE_OSX |
| decklinkoutput | ⚙️ | ⚙️ | HAVE_DECKLINK |
| direct3d11 | N/A | ⚙️ | Direct3D11 |
| direct3d11_filters | N/A | ⚙️ | Direct3D11 |
| direct3d9 | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| direct3d9_filters | N/A | ⚙️ | Direct3D9 |
| directdraw | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| egl_android | N/A | N/A | Android only |
| egl_win32 | N/A | ⚙️ | HAVE_WIN32 + HAVE_EGL |
| egl_wl | N/A | N/A | Wayland only |
| egl_x11 | N/A | N/A | X11 only |
| fb | N/A | N/A | Linux only |
| flaschen | ⚙️ | ⚙️ | Socket libraries |
| gl | ⚙️ | ⚙️ | HAVE_GL |
| glconv_android | N/A | N/A | Android only |
| glconv_cvpx | ⚙️ | N/A | HAVE_OSX or HAVE_IOS |
| glconv_vaapi_drm | N/A | N/A | Linux VA-API DRM |
| glconv_vaapi_wl | N/A | N/A | Linux VA-API Wayland |
| glconv_vaapi_x11 | N/A | N/A | Linux VA-API X11 |
| glconv_vdpau | N/A | N/A | Linux VDPAU |
| gles2 | ⚙️ | ⚙️ | glesv2 (disabled by default) |
| glspectrum | ⚙️ | ⚙️ | libprojectM |
| glwin32 | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| glx | N/A | N/A | X11 only |
| image | ✅ | ✅ | — |
| macosx | ⚙️ | N/A | HAVE_OSX |
| vout_macosx | ⚙️ | N/A | HAVE_OSX |
| vout_ios | N/A | N/A | iOS/tvOS only |
| vdummy / vmem | ✅ | ✅ | — |
| wayland / wl_shell / wl_shm | N/A | N/A | Wayland only |
| wgl | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| wingdi | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| win_hotkeys / winhibit | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| xcb_apps / xcb_hotkeys / xcb_screen / xcb_window / xcb_x11 / xcb_xv | N/A | N/A | X11 only |
| yuv | ✅ | ✅ | — |

---

## CODEC 模块（编解码器插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| a52 | ⚙️ | ⚙️ | liba52 |
| adpcm / aes3 | ✅ | ✅ | — |
| aom | ⚙️ | ⚙️ | aom |
| avcodec | ⚙️ | ⚙️ | libavcodec + MERGE_FFMPEG |
| avaudiocapture | ⚙️ | N/A | HAVE_AVFOUNDATION |
| avcapture | ⚙️ | N/A | HAVE_AVFOUNDATION |
| bpg | ⚙️ | ⚙️ | libbpg |
| cc / cvdsub / dvbsub | ✅ | ✅ | — |
| dca | ⚙️ | ⚙️ | libdca >= 0.0.5 (disabled by default) |
| dcp | ⚙️ | ⚙️ | HAVE_ASDCP + HAVE_GCRYPT |
| ddummy / edummy | ✅ | ✅ | — |
| dmo | N/A | ⚙️ | HAVE_WIN32 |
| d3d11va / dxva2 | N/A | ⚙️ | HAVE_AVCODEC_DXVA2/D3D11VA |
| faad | ⚙️ | ⚙️ | libfaad2 |
| flac | ⚙️ | ⚙️ | libflac |
| fluidsynth | ⚙️ | ⚙️ | libfluidsynth >= 1.1.2 |
| g711 / spdif | ✅ | ✅ | — |
| jpeg | ⚙️ | ⚙️ | libjpeg |
| kate | ⚙️ | ⚙️ | libkate >= 0.3.0 |
| libass | ⚙️ | ⚙️ | libass |
| mad | ⚙️ | ⚙️ | libmad |
| mft | N/A | ⚙️ | HAVE_WIN32 |
| mpg123 | ⚙️ | ⚙️ | libmpg123 |
| mpgv | ✅ | ✅ | — |
| opus / vorbis | ⚙️ | ⚙️ | libopus >= 1.0.3 / libvorbis |
| png | ⚙️ | ⚙️ | libpng |
| qsv | ⚙️ | ⚙️ | libmfx (Intel QuickSync) |
| schroedinger | ⚙️ | ⚙️ | schroedinger-1.0 >= 1.0.10 |
| sdl_image | ⚙️ | ⚙️ | SDL_image |
| shine | ⚙️ | ⚙️ | shine >= 3.0.0 (disabled by default) |
| speex / tremor | ⚙️ | ⚙️ | libspeex >= 1.0.5 / libvorbisidec |
| spudec / stl / svcdsub | ✅ | ✅ | — |
| svgdec | ⚙️ | ⚙️ | librsvg-2.0 >= 2.9.0 + cairo |
| telx / zvbi | ⚙️ | ⚙️ | libzvbi |
| theora | ⚙️ | ⚙️ | libtheora |
| ttml / subsdec / subsusf / substx3g | ✅ | ✅ | — |
| twolame | ⚙️ | ⚙️ | twolame |
| vpx | ⚙️ | ⚙️ | libvpx |
| webvtt | ✅ | ✅ | — |
| wma_fixed | ✅ | ✅ | — |
| x264 / x26410b | ⚙️ | ⚙️ | — (built-in) |
| x265 | ⚙️ | ⚙️ | x265 |
| dav1d | ⚙️ | ⚙️ | dav1d |
| fdkaac | ⚙️ | ⚙️ | fdk-aac (disabled by default) |
| libmpeg2 | ⚙️ | ⚙️ | libmpeg2 > 0.3.2 (disabled by default) |

---

## DEMUX 模块（解封装插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| aiff / avi / au / caf | ✅ | ✅ | — |
| asf / mp4 / mpegv | ✅ | ✅ | — |
| avformat | ⚙️ | ⚙️ | libavformat, !MERGE_FFMPEG |
| demux_cdg / demux_stl / demux_chromecast / demuxdump | ✅ | ✅ | — |
| diracsys | ⚙️ | ⚙️ | schroedinger |
| es / flacsys / h26x | ✅ | ✅ | — |
| gme | ⚙️ | ⚙️ | libgme |
| mkv | ⚙️ | ⚙️ | libebml >= 1.3.6 + libmatroska |
| mod | ⚙️ | ⚙️ | libmod |
| mpc | ⚙️ | ⚙️ | libmpcdec |
| ogg | ⚙️ | ⚙️ | libvorbis >= 1.1 + ogg >= 1.0 |
| ps | ✅ | ✅ | — |
| rawdv / rawvid / rawaud | ✅ | ✅ | — |
| real / sid | ⚙️ | ⚙️ | realmedia / libsidplay |
| subtitle / vobsub | ✅ | ✅ | — |
| ts | ⚙️ | ⚙️ | HAVE_DVBPSI |
| ttml / webvtt / wav | ✅ | ✅ | — |

---

## CONTROL 模块（控制插件）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| dbus | ⚙️ | ⚙️ | libdbus-1 |
| dbus_screensaver | ⚙️ | ⚙️ | libdbus-1 |
| dummy / gestures / hotkeys | ✅ | ✅ | — |
| lirc | N/A | N/A | Linux only |
| motion | ⚙️ | ❌ | HAVE_DARWIN |
| netsync | ⚙️ | ⚙️ | Socket libraries |
| ntservice | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| oldrc | ✅ | ✅ | Socket libraries |
| win_hotkeys / win_msg | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| xcb_hotkeys | N/A | N/A | X11 only |

---

## VIDEO_FILTER 模块（视频滤镜）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| adjust / anaglyph / canvas | ✅ | ✅ | — |
| alphamask / blend / bluescreen | ✅ | ✅ | — |
| ci_filters | ⚙️ | N/A | HAVE_OSX or HAVE_IOS |
| clone / colorthres | ✅ | ✅ | — |
| deinterlace | ✅ | ✅ | — |
| erase / extract / fps / freeze | ✅ | ✅ | — |
| goom | ⚙️ | ⚙️ | libgoom2 |
| gradfun / gaussianblur | ✅ | ✅ | — |
| grain / hqdn3d / invert | ✅ | ✅ | — |
| magnify / mirror / motionblur / motiondetect | ✅ | ✅ | — |
| oldmovie / posterize / psychedelic | ✅ | ✅ | — |
| opencv_example / opencv_wrapper | ⚙️ | ⚙️ | opencv > 2.0 |
| panoramix | ✅ | ✅ | — |
| postproc | ⚙️ | ⚙️ | libpostproc + libavutil |
| puzzle / ripple / rotate | ✅ | ✅ | — |
| scene / sepia / sharpen | ✅ | ✅ | — |
| transform / vhs / wave | ✅ | ✅ | — |

---

## AUDIO_FILTER 模块（音频滤镜）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| audio_format / bandlimited_resampler | ✅ | ✅ | — |
| charter (channel mixer) | ✅ | ✅ | — |
| chorus_flanger / compressor | ✅ | ✅ | — |
| dolby_surround_decoder | ✅ | ✅ | — |
| equalizer | ✅ | ✅ | — |
| gain / headphone_channel_mixer | ✅ | ✅ | — |
| karaoke / mono / normvol | ✅ | ✅ | — |
| param_eq / remap | ✅ | ✅ | — |
| scaletempo / scaletempo_pitch | ✅ | ✅ | — |
| simple_channel_mixer | ✅ | ✅ | — |
| soxr | ⚙️ | ⚙️ | soxr >= 0.1.2 |
| spatialaudio | ⚙️ | ⚙️ | spatialaudio |
| spatializer | ✅ | ✅ | — |
| speex_resampler | ⚙️ | ⚙️ | libspeexdsp |
| stereo_widen / tospdif | ✅ | ✅ | — |
| trivial_channel_mixer / ugly_resampler | ✅ | ✅ | — |
| samplerate | ⚙️ | ⚙️ | libsamplerate |

---

## TEXT_RENDERER 模块（字幕渲染）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| freetype | ⚙️ | ⚙️ | libfreetype |
| nsspeechsynthesizer | ⚙️ | N/A | HAVE_OSX |
| sapi | N/A | ⚙️ | HAVE_SAPI (Windows TTS) |
| svg | ⚙️ | ⚙️ | librsvg-2.0 >= 2.9.0 + cairo |
| tdummy | ✅ | ✅ | — |

---

## SERVICES_DISCOVERY 模块（服务发现）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| avahi | N/A | N/A | Linux only |
| bonjour | ⚙️ | N/A | HAVE_DARWIN |
| mediadirs / podcast | ✅ | ✅ | — |
| microdns | ⚙️ | ⚙️ | microdns >= 0.1.2 |
| sap | ✅ | ✅ | — |
| upnp | ⚙️ | ⚙️ | libupnp |
| pulselist | ⚙️ | ⚙️ | HAVE_PULSE |
| windrive | N/A | ⚙️ | HAVE_WIN32_DESKTOP |
| udev | N/A | N/A | Linux only |

---

## KEYSTORE 模块（密钥存储）

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| file_keystore | ✅ | ✅ | Platform crypto |
| keychain | ⚙️ | N/A | HAVE_OSX |
| kwallet | N/A | N/A | KDE only |
| memory_keystore | ✅ | ✅ | — |
| secret | ⚙️ | ⚙️ | libsecret-1 >= 0.18 |

---

## STREAM_FILTER 模块

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| adf | ✅ | ✅ | — |
| aribcam | ⚙️ | ⚙️ | aribb25 >= 0.2.6 |
| cache_block / cache_read | ✅ | ✅ | — |
| decomp | ⚙️ | ❌ | !HAVE_WIN32 |
| hds | ✅ | ✅ | — |
| inflate | ⚙️ | ⚙️ | HAVE_ZLIB |
| prefetch | ✅ | ❌ | !HAVE_WINSTORE |
| record | ✅ | ✅ | — |
| skiptags | ✅ | ✅ | — |

---

## MISC 模块

| 插件 | macOS | Windows | 依赖库 / 条件 |
|------|-------|---------|---------------|
| addonsfsstorage / addonsvorepository | ⚙️ | ⚙️ | ENABLE_ADDONMANAGERMODULES |
| audioscrobbler | ✅ | ✅ | Socket libraries |
| export | ✅ | ✅ | — |
| fingerprinter | ⚙️ | ⚙️ | libchromaprint |
| gnutls | ⚙️ | ⚙️ | gnutls |
| logger / console_logger / file_logger | ✅ | ✅ | — |
| securetransport | ⚙️ | N/A | HAVE_DARWIN |
| stats | ✅ | ✅ | — |
| xml | ⚙️ | ⚙️ | libxml-2.0 >= 2.5 |

---

## PACKETIZER 模块

全部默认启用（当 ENABLE_SOUT=yes）：
a52, av1, copy, dts, flac, h264, hevc, mlp, mpeg4audio, mpeg4video, mpegaudio, mpegvideo, vc1

---

## STREAM_OUT / MUX / ACCESS_OUTPUT 模块

全部默认启用（当 ENABLE_SOUT=yes），不需要显式配置。

---

## 平台独有插件

### macOS 独有（Windows 无）

| 插件 | 说明 |
|------|------|
| auhal | CoreAudio 音频输出 |
| audiounit_ios / audiotoolboxmidi | iOS/tvOS AudioUnit |
| bonjour | mDNS Bonjour 发现 |
| caopengllayer | CoreAnimation OpenGL |
| glconv_cvpx | Apple CVPX OpenGL 转换 |
| keychain | macOS 密钥链存储 |
| macosx / vout_macosx | macOS 视频输出 |
| nsspeechsynthesizer | macOS TTS |
| securetransport | macOS/iOS TLS |
| ntservice | Windows NT 服务（仅 Windows）|

### Windows 独有（macOS 无）

| 插件 | 说明 |
|------|------|
| d3d11va / d3d11va | Direct3D11 硬件解码 |
| direct3d9 / directdraw | Direct3D9/GDI 输出 |
| dmo | DirectMediaObject (WMV3) |
| dshow | DirectShow 采集 |
| dxva2 | DirectX VA2 硬件解码 |
| mmdevice / wasapi / waveout | Windows 音频 API |
| mft | Media Foundation Transform |
| wingdi / wgl | Windows GDI/WGL 输出 |
| win_hotkeys / win_msg / winhibit | Windows 热键/消息/屏保抑制 |
| windrive | Windows 逻辑驱动器 |

---

## 控制插件启用的方式

### 方式一：修改 configure.sh

`extras/package/macosx/configure.sh` 或 `extras/package/win32/configure.sh`：

```bash
# 启用插件
--enable-FAAD

# 禁用插件
--disable-skins2
```

### 方式二：传入额外参数

```bash
./extras/package/macosx/configure.sh --disable-skins2 "$@"
```

### 方式三：修改 Makefile.am 条件

在 `modules/*/Makefile.am` 中修改 `if HAVE_XXX` 条件。

---

## 相关文件

- `vlc-build/modules/MODULES_LIST` — 全部 491 个插件列表
- `vlc-build/configure.ac` — 插件检测逻辑
- `vlc-build/extras/package/macosx/configure.sh` — macOS 构建选项
- `vlc-build/extras/package/win32/configure.sh` — Windows 构建选项
