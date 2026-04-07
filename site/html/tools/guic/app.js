const EngineLoader = {
    async loadAll() {
        console.log("🛠️ Запуск системы UI: Elements & Modify...");
        
        await this.injectScript('UIE/src.js');

        await Promise.all([
            this.loadCategory('UIE'),
            this.loadCategory('UIP')
        ]);

        console.log("🚀 Все системы UIE и UIP загружены!");
        
        // Обновляем Explorer и Properties
        if (window.ExplorerEngine) {
            window.ExplorerEngine.render();
        }
    },

    async loadCategory(dir) {
        try {
            const response = await fetch(`${dir}/manifest.json`);
            if (!response.ok) return console.warn(`⚠️ Манифест для ${dir} не найден.`);
            
            const list = await response.json();
            for (const name of list) {
                await this.injectScript(`${dir}/${name}/src.js`, name, dir);
            }
        } catch (e) {
            console.error(`❌ Ошибка загрузки категории ${dir}:`, e);
        }
    },

    injectScript(src, name = '', dir = '') {
        return new Promise((resolve) => {
            const script = document.createElement('script');
            script.src = src;
            script.onload = () => {
                if (name && dir) {
                    console.log(`✅ [${dir}] Модуль загружен: ${name}`);
                    this.createToolBtn(name, dir);
                }
                resolve();
            };
            script.onerror = () => {
                console.error(`❌ Ошибка загрузки: ${src}`);
                resolve();
            };
            document.head.appendChild(script);
        });
    },

    createToolBtn(name, dir) {
        const containerId = dir === 'UIE' ? 'uie-list' : 'uip-list';
        const container = document.getElementById(containerId);
        if (!container) {
            console.warn(`Container ${containerId} not found`);
            return;
        }

        const btn = document.createElement('button');
        btn.className = 'tool-btn';
        btn.innerText = name;
        
        btn.onclick = () => {
            if (dir === 'UIE') {
                if (window.UIElements) {
                    console.log(`Создаем ${name}`);
                    window.UIElements.create(name);
                }
            } else if (dir === 'UIP') {
                if (typeof window.addEffect === 'function') {
                    console.log(`Добавляем эффект ${name}`);
                    window.addEffect(name);
                }
            }
        };
        
        container.appendChild(btn);
        console.log(`🔘 Кнопка ${name} добавлена в ${containerId}`);
    }
};

// --- Глобальное состояние ---
window.App = {
    zoom: 1, 
    panX: 150, 
    panY: 150,
    activeId: 'screen-gui',
    objCount: 0,
    snapDistance: 10,
    objects: { 
        'screen-gui': { 
            type: 'ScreenGui', 
            name: 'ScreenGui', 
            parent: null, 
            dom: document.getElementById('screen-gui'), 
            props: { BackgroundColor3: '#000000', ClipsDescendants: false },
            effects: []
        } 
    }
};

// --- Управление файлами ---
window.FileSystem = {
    saveProject(fileName = "project.obj.ml") {
        const data = JSON.stringify(App.objects, null, 4);
        const blob = new Blob([data], { type: "application/json" });
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.download = fileName;
        link.click();
    },
    loadProject(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            App.objects = JSON.parse(e.target.result);
            const startup = document.getElementById('startup-screen');
            if (startup) startup.style.display = 'none';
            
            if (window.ExplorerEngine) ExplorerEngine.render();
            if (window.PropertiesEngine) PropertiesEngine.render();
            console.log("📂 Проект загружен");
        };
        reader.readAsText(file);
    }
};

// --- Логика старта ---
window.Startup = {
    newProject() {
        const screen = document.getElementById('startup-screen');
        if (screen) screen.style.display = 'none';
        console.log("✨ Создан новый проект");
        
        setTimeout(() => {
            if (window.ExplorerEngine) {
                window.ExplorerEngine.render();
                window.ExplorerEngine.select('screen-gui');
            }
        }, 50);
    }
};

// --- Горячие клавиши ---
document.addEventListener('keydown', (e) => {
    if(e.key === 'Delete' && App.activeId !== 'screen-gui') {
        if (window.UIElements) UIElements.delete(App.activeId);
    }
    if(e.key === 'F2' && window.ExplorerEngine) {
        ExplorerEngine.renamePrompt(App.activeId);
    }
});


window.addEffect = function(typeName) {
    const data = window.RegistryP ? window.RegistryP[typeName] : null; 
    if (!data) return console.error(`Модификатор ${typeName} не найден!`);
    const parentId = App.activeId;
    const parentObj = App.objects[parentId];
    if (!parentObj) {
        return alert("❌ Объект не найден!");
    }
    if (!parentObj.effects) parentObj.effects = [];
    const effectId = `uip-${Date.now()}`;
    const effectData = {
        id: effectId,
        type: data.ElementName,
        name: `${data.ElementName}_${parentObj.effects.length + 1}`,
        parent: parentId,
        props: JSON.parse(JSON.stringify(data.ElementProperties))
    };
    parentObj.effects.push(effectData);
    App.objects[effectId] = {
        type: data.ElementName,
        name: effectData.name,
        parent: parentId,
        dom: null,
        props: effectData.props,
        isEffect: true
    };
    if (data.Apply && parentObj.dom) {
        data.Apply(parentObj.dom, effectData.props);
    }
    if (window.ExplorerEngine) {
        window.ExplorerEngine.render();
    }
    console.log(`Эффект ${typeName} добавлен к ${parentObj.name}`);
};

EngineLoader.loadAll();