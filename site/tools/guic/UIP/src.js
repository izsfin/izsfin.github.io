(function() {
    window.RegistryP = window.RegistryP || {};
    window.RegistryP['UICorner'] = {
        ElementName: "UICorner",
        ElementProperties: {
            CornerRadius: 8
        },
        Apply: function(parentEl, props) {
            LuaUtils.applyModifier(parentEl, "UICorner", props);
        }
    };
})();