(function() {
    const MetaData = {
        ElementName: "Frame",
        ElementProperties: {
            Size: { X: 100, Y: 100 },
            Position: { X: 50, Y: 50 },
            BackgroundColor3: "#ffffff",
            BackgroundTransparency: 0,
            ClipsDescendants: false
        },
        Init: (dom, props) => {
            dom.style.position = 'absolute';
            dom.style.width = props.Size.X + 'px';
            dom.style.height = props.Size.Y + 'px';
            dom.style.left = props.Position.X + 'px';
            dom.style.top = props.Position.Y + 'px';

            const r = parseInt(props.BackgroundColor3.slice(1,3), 16);
            const g = parseInt(props.BackgroundColor3.slice(3,5), 16);
            const b = parseInt(props.BackgroundColor3.slice(5,7), 16);
            dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - props.BackgroundTransparency})`;

            // Без дефолтной обводки — outline только через UIStroke
            dom.style.border = 'none';
            dom.style.boxSizing = 'border-box';
            dom.style.overflow = props.ClipsDescendants ? 'hidden' : 'visible';

            console.log("Frame initialized", props);
        }
    };

    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();