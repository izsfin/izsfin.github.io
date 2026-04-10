const SnappingEngine = {
    startDrag(e, id) {
        const obj = window.App.objects[id];
        if (!obj || !obj.dom) return;

        const el = obj.dom;
        const parent = el.parentElement;
        
        // Получаем начальную позицию элемента
        let startLeft = el.offsetLeft;
        let startTop = el.offsetTop;
        
        // Запоминаем начальные позиции ВСЕХ детей
        const children = this.getChildren(id);
        const childrenStartPos = {};
        children.forEach(childId => {
            const childObj = window.App.objects[childId];
            if (childObj && childObj.dom) {
                childrenStartPos[childId] = {
                    left: childObj.dom.offsetLeft,
                    top: childObj.dom.offsetTop
                };
            }
        });
        
        const gv = document.getElementById('g-v');
        const gh = document.getElementById('g-h');

        let startX = e.clientX;
        let startY = e.clientY;
        let isDragging = false;

        const move = (ev) => {
            isDragging = true;
            const zoom = window.App.zoom || 1;
            
            // Вычисляем общее смещение от начальной точки
            const totalDx = (ev.clientX - startX) / zoom;
            const totalDy = (ev.clientY - startY) / zoom;

            // Новая позиция = начальная позиция + общее смещение
            let newLeft = startLeft + totalDx;
            let newTop = startTop + totalDy;

            // Примагничивание
            const snapDist = 1;
            if (gv) gv.style.display = 'none';
            if (gh) gh.style.display = 'none';

            const parentWidth = parent.clientWidth;
            const parentHeight = parent.clientHeight;
            const elWidth = el.offsetWidth;
            const elHeight = el.offsetHeight;

            const targetsX = [0, (parentWidth - elWidth) / 2, parentWidth - elWidth];
            const targetsY = [0, (parentHeight - elHeight) / 2, parentHeight - elHeight];

            targetsX.forEach((t, i) => {
                if (Math.abs(newLeft - t) < snapDist) {
                    newLeft = t;
                    if (gv) {
                        gv.style.display = 'block';
                        gv.style.left = (i === 0 ? "0%" : (i === 1 ? "50%" : "100%"));
                    }
                }
            });

            targetsY.forEach((t, i) => {
                if (Math.abs(newTop - t) < snapDist) {
                    newTop = t;
                    if (gh) {
                        gh.style.display = 'block';
                        gh.style.top = (i === 0 ? "0%" : (i === 1 ? "50%" : "100%"));
                    }
                }
            });

            // Применяем новую позицию к элементу
            el.style.left = newLeft + 'px';
            el.style.top = newTop + 'px';
            
            // Перемещаем детей относительно ИХ начальной позиции + общее смещение родителя
            const deltaX = newLeft - startLeft;
            const deltaY = newTop - startTop;
            
            children.forEach(childId => {
                const childObj = window.App.objects[childId];
                const startPos = childrenStartPos[childId];
                if (childObj && childObj.dom && startPos) {
                    childObj.dom.style.left = (startPos.left + deltaX) + 'px';
                    childObj.dom.style.top = (startPos.top + deltaY) + 'px';
                }
            });
        };

        const stop = () => {
            window.removeEventListener('mousemove', move);
            window.removeEventListener('mouseup', stop);
            
            if (gv) gv.style.display = 'none';
            if (gh) gh.style.display = 'none';
            
            if (isDragging) {
                // Сохраняем финальную позицию в props
                const finalLeft = parseFloat(el.style.left) || 0;
                const finalTop = parseFloat(el.style.top) || 0;
                
                if (!obj.props.Position) obj.props.Position = {};
                obj.props.Position.X = finalLeft;
                obj.props.Position.Y = finalTop;
                
                // Сохраняем позиции детей
                children.forEach(childId => {
                    const childObj = window.App.objects[childId];
                    if (childObj && childObj.dom) {
                        const childLeft = parseFloat(childObj.dom.style.left) || 0;
                        const childTop = parseFloat(childObj.dom.style.top) || 0;
                        if (!childObj.props.Position) childObj.props.Position = {};
                        childObj.props.Position.X = childLeft;
                        childObj.props.Position.Y = childTop;
                    }
                });
                
                // Обновляем Properties один раз после драга
                if (window.PropertiesEngine) {
                    window.PropertiesEngine.render();
                }
                console.log(`✅ ${obj.name} перемещен на (${finalLeft}, ${finalTop})`);
            }
        };

        window.addEventListener('mousemove', move);
        window.addEventListener('mouseup', stop);
    },
    
    getChildren(parentId) {
        const children = [];
        const findChildren = (pid) => {
            Object.keys(window.App.objects).forEach(id => {
                const obj = window.App.objects[id];
                if (obj && obj.parent === pid && !obj.isEffect) {
                    children.push(id);
                    findChildren(id);
                }
            });
        };
        findChildren(parentId);
        return children;
    }
};

window.SnappingEngine = SnappingEngine;