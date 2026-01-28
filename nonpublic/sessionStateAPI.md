# Session State API Documentation

## Overview
Apps automatically persist their state across page refreshes when session state is enabled. Form inputs, textareas, selects, and scroll positions are captured and restored automatically - **no custom code required!**

## Enabling Session State

Simply add to your `app.properties.json`:
```json
{
  "sessionState": true,
  "maxInstances": -1
}
```

That's it! Your app now has automatic state persistence.

## Automatic State Capture

The system automatically saves and restores:

### Form Elements (with `id` or `name` attributes)
- `<input>` of all types (text, email, password, number, checkbox, radio, etc.)
- `<textarea>` content
- `<select>` dropdown selections
- Elements with `contenteditable="true"`

### Other States
- Scroll positions (both X and Y axes)
- All captured automatically without code

**Example:** This works automatically:
```html
<input id="username" type="text" />
<input id="remember" type="checkbox" />
<textarea id="notes"></textarea>
<select id="theme">
  <option>Light</option>
  <option>Dark</option>
</select>
```

## Custom State Management (Optional)

If you need to save custom data beyond form inputs, you can implement these optional functions:

### 1. Save State
```javascript
// OPTIONAL - only if you need custom state beyond form inputs
window.getAppSessionState = function() {
  // Return any JSON-serializable object
  return {
    canvasData: myCanvas.toDataURL(),
    videoTime: myVideo.currentTime,
    customSettings: { theme: 'dark', zoom: 1.5 }
  };
};
```

### 2. Restore State
```javascript
// OPTIONAL - only if you need custom state restoration
window.restoreAppSessionState = function(state) {
  if (!state) return;
  
  // Restore your custom state
  if (state.canvasData) {
    loadCanvasFromData(state.canvasData);
  }
  if (state.videoTime) {
    myVideo.currentTime = state.videoTime;
  }
  if (state.customSettings) {
    applySettings(state.customSettings);
  }
};
```

**Note:** If you define custom functions, they take precedence over automatic capture. If you want both automatic AND custom state, make sure to call the automatic capture:

## Available Context

Apps can use these properties if needed:
- Each window has a unique `instanceId` stored in `win.dataset.instanceId`
- Window's app key is in `win.dataset.appKey`

## Examples

### Example 1: Simple Form (Automatic - No Code Needed!)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Contact Form</title>
</head>
<body>
  <form>
    <input id="name" type="text" placeholder="Name" />
    <input id="email" type="email" placeholder="Email" />
    <textarea id="message" placeholder="Message"></textarea>
    <input id="subscribe" type="checkbox" /> Subscribe to newsletter
    <button type="submit">Send</button>
  </form>
</body>
</html>
```
**State is automatically saved and restored!** Just enable `sessionState: true` in properties.

### Example 2: Note-taking App (Automatic)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Notes</title>
</head>
<body>
  <textarea id="notepad" style="width:100%;height:400px;"></textarea>
  <!-- Automatically saved! No script needed -->
</body>
</html>
```

### Example 3: Custom State (Optional Functions)

### Example 3: Custom State (Optional Functions)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Drawing App</title>
</head>
<body>
  <canvas id="canvas" width="800" height="600"></canvas>
  
  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    
    // Custom save function for canvas data
    window.getAppSessionState = function() {
      return {
        canvasData: canvas.toDataURL()
      };
    };
    
    // Custom restore function
    window.restoreAppSessionState = function(state) {
      if (state?.canvasData) {
        const img = new Image();
        img.onload = () => ctx.drawImage(img, 0, 0);
        img.src = state.canvasData;
      }
    };
  </script>
</body>
</html>
```

## Best Practices

1. **Use `id` or `name` attributes** - Elements need these for automatic state capture
2. **Keep state small** - Large canvas/media data may slow down saves
3. **Test thoroughly** - Verify state persists correctly across refreshes
4. **Optional custom functions** - Only implement if you need state beyond form inputs
5. **JSON-serializable data only** - No functions, DOM elements, or circular references

## Limitations

- Elements must have `id` or `name` attributes for automatic capture
- State is saved every 30 seconds (automatic save interval)
- State is saved on page unload
- State must be JSON-serializable
- Apps with `sessionState: false` won't have state persistence
