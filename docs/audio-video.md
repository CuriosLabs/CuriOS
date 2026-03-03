# Audio and Video Applications

Curi*OS* comes with powerful multimedia tools pre-installed and offers easy
access to professional-grade creative software.

## Default Applications

The following applications are installed by default on Curi*OS* to handle your
daily multimedia needs:

- **VLC Media Player**: A versatile media player that supports almost every audio
and video format.
- **Gimp 3**: The latest version of the GNU Image Manipulation Program for advanced
image editing and graphic design.
- **EasyEffects**: An advanced audio manipulation tool to apply effects to your input
(microphone) and output (speakers/headphones) audio devices.

![EasyEffects application](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Desktop6.png?raw=true "EasyEffects application.")

## Professional Studio Suite

For creators and professionals, Curi*OS* offers a "Studio" suite containing
industry-standard tools for video editing, audio recording, and photography.

![Studio applications](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Desktop-studio.png?raw=true "Studio applications.")

You can enable these applications via the **Curi*OS* Manager**:

1. Open `curios-manager` (Shortcut: `Super+Return`).
2. Go to `Settings (manual edit)`.
3. Set `studio.enable = true;`.
4. Save and exit (`Ctrl+X`).

This will install:

- **OBS Studio**: Software for video recording and live streaming.
- **Audacity**: Easy-to-use, multi-track audio editor and recorder.
- **DaVinci Resolve**: Professional video editing, color correction, visual effects,
and audio post-production.
- **Darktable**: An open-source photography workflow application and raw developer.

## Audio Enhancement with EasyEffects

**EasyEffects** is a powerful tool installed by default that allows you to apply
system-wide audio effects. It is particularly useful for improving the sound
quality of headphones or microphones. Visit [EasyEffects wiki](https://github.com/wwmm/easyeffects/wiki) for more informations.

### Improving Headphone Experience

You can significantly enhance your listening experience by applying an **Equalizer**
matched to your specific headphone model.

1. **Launch EasyEffects** from the application menu.
2. **Add an Equalizer Effect**:
   - Click on the **Output** tab (for speakers/headphones).
   - Click **Add Effect** and select **Equalizer**.
3. **Import an AutoEQ Profile**:
   - Visit [AutoEQ.app](https://autoeq.app/).
   - Search for your specific headphone model.
   - Select your headphone and choose the **EasyEffects** application type.
   - Download the generated configuration file (usually a `.txt` file).
   - In EasyEffects, inside the Equalizer effect settings, click on **Import APO**
   (or "Load APO Preset").
   - Select the file you downloaded from AutoEQ.

This process flattens the frequency response of your headphones, providing a
more neutral and high-fidelity sound, which you can then further tweak to your
preference.

If you are satisfied with your EasyEffects setup, do not forget to set up the
auto start option on user connexion in the application preferences menu.

---
**Previous**: [Working with AI tools](ai-tools.md)

**Back**: [index](index.md).
