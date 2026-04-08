(function() {
    const MetaData = {
        ElementName: "TextLabel",
        ElementProperties: {
            Size: { X: 120, Y: 36 },
            Position: { X: 50, Y: 50 },
            BackgroundColor3: "#2d2d2d",
            BackgroundTransparency: 0,
            Text: "TextLabel",
            TextSize: 14,
            TextColor3: "#ffffff"
        },
        Init: (dom, props) => {
            dom.style.position = 'absolute';
            dom.style.width = props.Size.X + 'px';
            dom.style.height = props.Size.Y + 'px';
            dom.style.left = props.Position.X + 'px';
            dom.style.top = props.Position.Y + 'px';
            dom.style.border = 'none';
            dom.style.boxSizing = 'border-box';

            const r = parseInt(props.BackgroundColor3.slice(1,3), 16);
            const g = parseInt(props.BackgroundColor3.slice(3,5), 16);
            const b = parseInt(props.BackgroundColor3.slice(5,7), 16);
            dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - props.BackgroundTransparency})`;

            dom.style.display = 'flex';
            dom.style.alignItems = 'center';
            dom.style.justifyContent = 'center';
            dom.style.fontSize = props.TextSize + 'px';
            dom.style.color = props.TextColor3;
            dom.style.fontFamily = 'Arial, sans-serif';
            dom.style.overflow = 'hidden';
            dom.innerText = props.Text;
            console.log("TextLabel initialized", props);
        }
    };

    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();