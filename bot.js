require("dotenv").config()
const { Client, GatewayIntentBits, AttachmentBuilder } = require("discord.js")
const { execFile, exec } = require("child_process")
const fs   = require("fs")
const path = require("path")
const https = require("https")
const http  = require("http")
const os    = require("os")

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
    ],
})

const LUA_BIN        = process.env.LUA_BIN        || "luajit"
const PROMETHEUS_CLI = process.env.PROMETHEUS_CLI  || "./Prometheus/cli.lua"

// ── Download helper ───────────────────────────────────────────
function download(url, dest) {
    return new Promise((resolve, reject) => {
        const proto = url.startsWith("https") ? https : http
        const file  = fs.createWriteStream(dest)
        proto.get(url, res => {
            res.pipe(file)
            file.on("finish", () => file.close(resolve))
        }).on("error", err => {
            fs.unlink(dest, () => {})
            reject(err)
        })
    })
}

// ── Run Prometheus ────────────────────────────────────────────
function runPrometheus(inputFile, outputFile, preset) {
    return new Promise((resolve, reject) => {
        const args = [
            PROMETHEUS_CLI,
            "--preset", preset,
            inputFile,
            "--out", outputFile
        ]
        execFile(LUA_BIN, args, { timeout: 30_000 }, (err, stdout, stderr) => {
            if (err && !fs.existsSync(outputFile)) {
                reject(new Error(stderr || err.message))
            } else {
                resolve(stdout)
            }
        })
    })
}

// ── Ready ────────────────────────────────────────────────────
client.once("ready", () => {
    console.log(`✅ Logged in as ${client.user.tag}`)
    client.user.setActivity("!obf <file.lua>")
})

// ── Messages ─────────────────────────────────────────────────
client.on("messageCreate", async msg => {
    if (msg.author.bot) return

    // !help
    if (msg.content.trim() === "!help") {
        return msg.reply(
            "```\n" +
            "Prometheus Obfuscator Bot\n" +
            "─────────────────────────\n" +
            "!obf          แนบ .lua → obfuscate ด้วย preset Medium\n" +
            "!obf strong   แนบ .lua → preset Strong (แรงสุด)\n" +
            "!obf weak     แนบ .lua → preset Minify (เบาสุด)\n" +
            "!help         แสดงคำช่วยเหลือนี้\n" +
            "```"
        )
    }

    // !obf
    if (!msg.content.trim().toLowerCase().startsWith("!obf")) return

    // parse preset
    const parts  = msg.content.trim().split(/\s+/)
    const presetArg = parts[1] ? parts[1].toLowerCase() : "medium"
    const presetMap = {
        weak   : "Minify",
        medium : "Medium",
        strong : "Strong",
    }
    const preset = presetMap[presetArg] || "Medium"

    const attachment = msg.attachments.find(
        a => a.name?.endsWith(".lua") || a.name?.endsWith(".txt")
    )

    if (!attachment) {
        return msg.reply("❌ แนบไฟล์ `.lua` มาด้วย")
    }

    if (attachment.size > 500_000) {
        return msg.reply("❌ ไฟล์ใหญ่เกิน 500KB")
    }

    const status = await msg.reply(`⏳ กำลัง obfuscate ด้วย preset **${preset}**...`)

    const uid      = Date.now() + "_" + Math.random().toString(36).slice(2)
    const tmpDir   = os.tmpdir()
    const inFile   = path.join(tmpDir, `prometheus_in_${uid}.lua`)
    const outFile  = path.join(tmpDir, `prometheus_out_${uid}.lua`)

    try {
        await download(attachment.url, inFile)
        await runPrometheus(inFile, outFile, preset)

        if (!fs.existsSync(outFile)) throw new Error("ไม่พบ output file")

        const result = fs.readFileSync(outFile, "utf-8")
        if (!result.trim()) throw new Error("output ว่างเปล่า")

        const outName = attachment.name.replace(/\.(lua|txt)$/, `_${preset.toLowerCase()}.lua`)
        const file    = new AttachmentBuilder(Buffer.from(result, "utf-8"), { name: outName })

        await status.edit({
            content: `✅ **Obfuscated** \`${attachment.name}\` → preset **${preset}** (${result.length} chars)`,
            files  : [file],
        })
    } catch (err) {
        console.error(err)
        await status.edit(`❌ Error: \`${err.message}\``)
    } finally {
        for (const f of [inFile, outFile]) {
            try { fs.unlinkSync(f) } catch {}
        }
    }
})

client.login(process.env.DISCORD_TOKEN)
