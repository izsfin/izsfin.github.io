export default async function handler(req, res) {
    if (req.method !== 'POST') return res.status(405).end();

    const { ip, path, domain, userAgent } = req.body;
    const isRoblox = userAgent.includes("Roblox");
    
    const discordPayload = {
        username: "Aqusu Firewall",
        embeds: [{
            title: isRoblox ? "✅ Script Loaded" : "🛡️ Access Blocked",
            color: isRoblox ? 0xd68efa : 0xd68efa, 
            fields: [
                { name: "🌐 Domain", value: `\`${domain}\``, inline: true },
                { name: "📁 File", value: `\`${path || "root"}\``, inline: true },
                { name: "👤 User-Agent", value: `\`\`\`${userAgent}\`\`\``, inline: false },
                { name: "📍 IP Info", value: `**IP:** ${ip}`, inline: false }
            ],
            footer: { text: `aqusu filter - ${new Date().toLocaleString('ru-RU')}` }
        }]
    };

    try {
        await fetch(process.env.DISCORD_WEBHOOK, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(discordPayload)
        });
        return res.status(200).json({ success: true });
    } catch (e) {
        return res.status(500).end();
    }
}
