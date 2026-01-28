# Session State Feature - Quick Start Guide

## ✅ Feature Implemented

Your Frutiger Aero OS now supports session state restoration for web-based apps! Each app instance can now save and restore its internal state across page refreshes.

## 🚀 How to Use

### For Users:
1. Open any app with `sessionState: true`
2. Fill in forms, type text, scroll, etc.
3. Refresh the page (F5)
4. Everything is automatically restored!

### For App Developers:

#### 1. Enable in app.properties.json:
```json
{
  "sessionState": true,
  "maxInstances": -1
}
```

#### 2. That's it! 🎉

**Automatic state capture includes:**
- All `<input>` fields (text, checkbox, radio, etc.)
- All `<textarea>` elements
- All `<select>` dropdowns
- All `contenteditable` elements
- Scroll positions (horizontal and vertical)

**No custom code needed!** The system automatically captures and restores all form elements.

#### 3. (Optional) Custom State Management

If you need to save custom data beyond form inputs, you can still implement custom functions:

```javascript
// Optional: Save custom state
window.getAppSessionState = function() {
  return {
    customData: "your custom state",
    anyData: { you: "want" }
  };
};

// Optional: Restore custom state
window.restoreAppSessionState = function(state) {
  if (state) {
    // Restore your custom state
  }
};
```

**Note:** Custom functions take precedence over automatic capture.

## 📝 Example Apps

### Notepad App
Location: `/public/apps/notepad/`
- Full session state implementation
- Saves text content, cursor position, scroll position
- Demonstrates all best practices

## 🔧 Technical Details

### What Gets Saved Automatically:
- All form input values (text, email, password, number, etc.)
- Checkbox and radio button states
- Dropdown selections
- Textarea content
- Contenteditable element content
- Horizontal and vertical scroll positions
- Window positions, sizes, and states

### What Can Be Saved Manually (with custom functions):
- Canvas/SVG data
- Video/audio playback positions
- Custom JavaScript objects
- LocalStorage/SessionStorage data
- Any other app-specific state

### When State is Saved:
- Every 30 seconds (automatic)
- On page unload/refresh
- On window close (for cleanup)

### How It Works:
1. Apps with `sessionState: true` define two global functions
2. Parent window calls these functions directly (no iframes)
3. App's state is collected and saved
4. State is saved to server
5. On reload, state is injected back into the app

## 🎯 Use Cases

- **Notepad/Text Editor**: Save document content
- **Forms**: Preserve user input
- **Settings**: Remember user preferences
- **Media Players**: Remember playback position
- **Games**: Save game state
- **Drawing Apps**: Save canvas state

## 📚 Full Documentation

See `sessionStateAPI.md` for complete API documentation and advanced examples.

## 🧪 Testing

1. Open Notepad app
2. Type: "Testing session state feature"
3. Add a timestamp
4. Refresh the page (F5)
5. ✓ Content should be restored!

## 🐛 Troubleshooting

**State not saving?**
- Check console for errors
- Ensure `sessionState: true` in app.properties.json
- Verify `getAppSessionState()` returns valid JSON

**State not restoring?**
- Check if `restoreAppSessionState()` is defined
- Look for console messages about state restoration

**App not working?**
- Session state runs apps normally (no iframes)
- All CSS/JS should work as expected
- Check browser console for errors

## 💡 Tips

1. Keep state objects small and focused
2. Always handle missing/null state gracefully
3. Test restoration with various states
4. Use console.log to debug state save/restore
5. Remember: only JSON-serializable data works
