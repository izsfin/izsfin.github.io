(function() {
    const MetaData = {
        ElementName: "UICorner",
        ElementProperties: {
            CornerRadius: 8
        },
        Apply: (dom, props) => {
            if (dom) {
                const radius = props.CornerRadius || 8;
                dom.style.borderRadius = radius + 'px';
                dom.style.overflow = 'hidden';
                console.log(`✅ UICorner applied to ${dom.id || 'element'}: radius ${radius}px`);
            }
        }
    };

    if (!window.RegistryP) window.RegistryP = {};
    window.RegistryP[MetaData.ElementName] = MetaData;
})();