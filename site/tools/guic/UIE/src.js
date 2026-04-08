// X:\Projects\guic\UIE\src.js

window.UIElements = {
    create(typeName, parentId = App.activeId) {
        const data = window.Registry[typeName];
        if (!data) return console.error(`Модуль ${typeName} не найден!`);

        App.objCount++;
        const id = 'obj-' + App.objCount;

        // Создаем DOM
        const el = document.createElement(typeName.includes('Button') ? 'button' : 'div');
        el.id = id;
        el.className = 'rbx-obj';
        
        // Базовые стили (можно вынести в CSS)
        Object.assign(el.style, {
            position: 'absolute',
            width: '100px',
            height: '100px',
            left: '50px',
            top: '50px',
            backgroundColor: data.ElementProperties.BackgroundColor3 || '#ffffff'
        });

        const parent = App.objects[parentId]?.dom || document.getElementById('screen-gui');
        parent.appendChild(el);

        // Регистрация в App
        App.objects[id] = {
            type: typeName,
            name: `${typeName}_${App.objCount}`,
            parent: parentId,
            dom: el,
            props: JSON.parse(JSON.stringify(data.ElementProperties)),
            effects: []
        };

        // Инициализация специфики (если есть)
        if (data.Init) data.Init(el, App.objects[id].props);

        // События
        el.onmousedown = (e) => {
            e.stopPropagation();
            if (window.ExplorerEngine) ExplorerEngine.select(id);
            if (window.SnappingEngine) SnappingEngine.startDrag(e, id);
        };

        if (window.ExplorerEngine) ExplorerEngine.render();
        if (window.Viewport && Viewport.makeDraggable) Viewport.makeDraggable(el);
    },

    delete(id) {
        if (id === 'screen-gui') return;
        if (App.objects[id]) {
            App.objects[id].dom.remove();
            delete App.objects[id];
            App.activeId = 'screen-gui';
            if (window.ExplorerEngine) {
                window.ExplorerEngine.render();
                window.ExplorerEngine.select('screen-gui');
            }
        }
    }
};