// lua_utils.js - Ядро визуализации редактора
const LuaUtils = {
    // Обновляет все стили элемента на основе его пропсов
    updateElementPhysics(el, props) {
        if (!el || !props) return;

        // Позиция и размер
        if (props.Position) {
            el.style.left = (props.Position.X || 0) + 'px';
            el.style.top = (props.Position.Y || 0) + 'px';
        }
        if (props.Size) {
            el.style.width = (props.Size.X || 100) + 'px';
            el.style.height = (props.Size.Y || 100) + 'px';
        }

        // Цвета и прозрачность
        if (props.BackgroundColor3) {
            const hex = props.BackgroundColor3;
            const r = parseInt(hex.slice(1, 3), 16);
            const g = parseInt(hex.slice(3, 5), 16);
            const b = parseInt(hex.slice(5, 7), 16);
            const trans = props.BackgroundTransparency || 0;
            el.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - trans})`;
        }

        // Специфичные для текста поля
        if (props.Text !== undefined) el.innerText = props.Text;
        if (props.TextColor3) el.style.color = props.TextColor3;
        if (props.TextSize) el.style.fontSize = props.TextSize + 'px';
        
        // ClipsDescendants
        if (props.ClipsDescendants !== undefined) {
            el.style.overflow = props.ClipsDescendants ? 'hidden' : 'visible';
        }
    },

    // Логика для UIP (Модификаторов) в редакторе
    applyModifier(parentEl, type, props) {
        if (!parentEl) return;

        if (type === 'UICorner') {
            parentEl.style.borderRadius = (props.CornerRadius || 0) + 'px';
        }
        
        if (type === 'UIStroke') {
            const thickness = props.Thickness || 1;
            const color = props.Color || '#000000';
            parentEl.style.outline = `${thickness}px solid ${color}`;
        }
    }
};