const ExportEngine = {
    generateLua() {
        let code = "--[[ § Exported by ML Expert Editor v1.1 § ]]\n\n";

        Object.keys(App.objects).forEach(id => {
            const obj = App.objects[id];
            const varName = id.replace(/-/g, "_");
            
            if (id === 'screen-gui') {
                code += `local ScreenGui = Instance.new("ScreenGui")\n`;
                code += `ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")\n\n`;
                return;
            }

            code += `local ${varName} = Instance.new("${obj.type}")\n`;
            code += `${varName}.Name = "${obj.name}"\n`;

            const data = obj.props ? obj.props : obj;

            Object.keys(data).forEach(prop => {
                const internalFields = ['type', 'name', 'parent', 'props', 'id'];
                if (internalFields.includes(prop)) return;

                let value = data[prop];
                if (value === undefined || value === null) return;

                // 🔥 1. Color3 HEX
                if (prop.includes('Color3') && typeof value === 'string' && value.startsWith('#')) {
                    const r = parseInt(value.slice(1, 3), 16);
                    const g = parseInt(value.slice(3, 5), 16);
                    const b = parseInt(value.slice(5, 7), 16);
                    code += `${varName}.${prop} = Color3.fromRGB(${r}, ${g}, ${b})\n`;
                }

                // 🔥 2. Size / Position (объект)
                else if ((prop === 'Size' || prop === 'Position') && typeof value === 'object') {
                    const sx = value.x?.scale || 0;
                    const ox = value.x?.offset || 0;
                    const sy = value.y?.scale || 0;
                    const oy = value.y?.offset || 0;
                    code += `${varName}.${prop} = UDim2.new(${sx}, ${ox}, ${sy}, ${oy})\n`;
                }

                // 🔥 3. ЛЮБОЙ UDim2 в строке (CanvasSize фикс)
                else if (typeof value === 'string' && value.includes(',')) {
                    const parts = value.split(',').map(v => Number(v.trim()));

                    if (parts.length === 4 && parts.every(v => !isNaN(v))) {
                        code += `${varName}.${prop} = UDim2.new(${parts.join(', ')})\n`;
                    } else {
                        code += `${varName}.${prop} = "${value}"\n`;
                    }
                }

                // 🔥 4. обычные строки
                else if (typeof value === 'string') {
                    code += `${varName}.${prop} = "${value}"\n`;
                }

                // 🔥 5. числа / bool
                else if (typeof value === 'number' || typeof value === 'boolean') {
                    code += `${varName}.${prop} = ${value}\n`;
                }
            });

            if (obj.parent) {
                const pVar = obj.parent === 'screen-gui' ? "ScreenGui" : obj.parent.replace(/-/g, "_");
                code += `${varName}.Parent = ${pVar}\n`;
            }

            code += "\n";
        });

        this.showPopup(code);
    },

    showPopup(code) {
        const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>ML UI Creator - Export</title>
            <style>
                body {
                    margin: 0; padding: 0;
                    background-color: #1a1a1a;
                    background-image: radial-gradient(#333 1px, transparent 1px);
                    background-size: 20px 20px;
                    color: #e0e0e0;
                    font-family: 'Consolas', 'Monaco', monospace;
                    display: flex; flex-direction: column;
                    height: 100vh; overflow: hidden;
                }
                .header {
                    background: rgba(0, 0, 0, 0.6);
                    padding: 10px 20px;
                    border-bottom: 1px solid #333;
                    backdrop-filter: blur(5px);
                    font-size: 14px;
                }
                .container {
                    position: relative;
                    flex-grow: 1;
                    margin: 20px;
                    display: flex;
                    flex-direction: column;
                }
                pre {
                    margin: 0; 
                    padding: 20px;
                    background: rgba(30, 30, 30, 0.5);
                    border: 1px solid rgba(68, 68, 68, 0.3);
                    border-radius: 8px;
                    overflow: auto;
                    line-height: 1.5;
                    flex-grow: 1;
                    backdrop-filter: blur(5px); 
                    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                    white-space: pre-wrap;
                    word-break: break-all;
                    font-size: 14px;
                }
                .copy-btn {
                    position: absolute;
                    top: 10px; right: 10px;
                    background: #444;
                    border: 1px solid #666;
                    color: #fff;
                    padding: 8px 18px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 13px;
                    z-index: 100;
                    transition: 0.2s;
                }
                .copy-btn:hover { background: #00a2ff; border-color: #00a2ff; }
                ::-webkit-scrollbar { width: 8px; }
                ::-webkit-scrollbar-thumb { background: #444; border-radius: 4px; }
            </style>
        </head>
        <body>
            <div class="header">ML Expert Editor v1.1 (lua.mle)</div>
            <div class="container">
                <button class="copy-btn" id="copyBtn">Copy Code</button>
                <pre id="code-block">${code}</pre>
            </div>
            <script>
                document.getElementById('copyBtn').addEventListener('click', function() {
                    const code = document.getElementById('code-block').textContent;
                    navigator.clipboard.writeText(code).then(() => {
                        this.innerText = 'Copied!';
                        this.style.background = '#28a745';
                        setTimeout(() => {
                            this.innerText = 'Copy Code';
                            this.style.background = '#444';
                        }, 2000);
                    });
                });
            </script>
        </body>
        </html>`;

        const blob = new Blob([htmlContent], { type: 'text/html' });
        window.open(URL.createObjectURL(blob), "_blank");
    }
};