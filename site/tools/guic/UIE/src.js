// UIE/Frame/src.js
(function() {
    window.Registry = window.Registry || {};
    window.Registry['Frame'] = {
        ElementName: "Frame",
        ElementProperties: {
            Size: { X: 100, Y: 100 },
            Position: { X: 0, Y: 0 },
            BackgroundColor3: "#ffffff",
            BackgroundTransparency: 0,
            ClipsDescendants: false
        },
        // Вместо огромного кода рендеринга просто вызываем ядро
        Init: function(el, props) {
            LuaUtils.updateElementPhysics(el, props);
        }
    };
})();