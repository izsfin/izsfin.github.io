(function() {
    const MetaData = {
        ElementName: "UIStroke",
        ElementProperties: {
            Thickness: 2,
            Color: "#ffffff",
            ApplyStrokeMode: "Frame"
        },
        Apply: (dom, props) => {
            if (!dom) return;
            const thickness = props.Thickness || 2;
            const color = props.Color || '#ffffff';
            const mode = props.ApplyStrokeMode || 'Frame';

            if (mode === 'Frame') {
                dom.style.outline = `${thickness}px solid ${color}`;
                dom.style.outlineOffset = '0px';
                dom.style.webkitTextStroke = '';
            } else if (mode === 'Text') {
                dom.style.outline = '';
                dom.style.webkitTextStroke = `${thickness}px ${color}`;
            }
            console.log(`✅ UIStroke (${mode}) applied to ${dom.id}: ${thickness}px ${color}`);
        }
    };

    if (!window.RegistryP) window.RegistryP = {};
    window.RegistryP[MetaData.ElementName] = MetaData;
})();