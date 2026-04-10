window.RegistryP['UICorner'] = {
    ElementName: "UICorner",
    ElementProperties: { CornerRadius: 8 },
    Apply: function(parentDom, props) {
        LuaUtils.applyModifier(parentDom, "UICorner", props);
    }
};