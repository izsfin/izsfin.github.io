(function() {
    const MetaData = {
        ElementName: "UIGradient",
        ElementProperties: {
            Rotation: 0,
            Color1: "#ff0000",
            Color2: "#0000ff"
        },
        Apply: (dom, props) => {
            if (dom) {
                const rotation = props.Rotation || 0;
                const color1 = props.Color1 || "#ff0000";
                const color2 = props.Color2 || "#0000ff";
                dom.style.backgroundImage = `linear-gradient(${rotation}deg, ${color1}, ${color2})`;
                console.log(`✅ UIGradient applied to ${dom.id || 'element'}: rotation ${rotation}deg`);
            }
        }
    };

    if (!window.RegistryP) window.RegistryP = {};
    window.RegistryP[MetaData.ElementName] = MetaData;
})();