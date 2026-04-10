window.Registry['Frame'] = {
    ElementName: "Frame",
    ElementProperties: {
        Size: { X: 100, Y: 100 },
        Position: { X: 50, Y: 50 },
        BackgroundColor3: '#ffffff',
        BackgroundTransparency: 0,
        BorderSizePixel: 1
    },
    Init: function(el, props) {
        LuaUtils.updateElement(el, props);
        if (props.BorderSizePixel) {
            el.style.border = `${props.BorderSizePixel}px solid #000000`;
        }
    }
};