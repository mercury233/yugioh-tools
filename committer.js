#!/usr/bin/env node

const util = require('util');
const pExecFile = util.promisify(require('child_process').execFile);
const fs = require('fs');

(async () => {
    let res = await pExecFile('git', ['log', '--name-only', '--format='], { cwd: process.cwd() });
    let allFiles = Array.from(new Set(res.stdout.split(/\n/)));
    let fileDatas = [];
    for (let file of allFiles) {
        //file = "scripts/VJMP-JP/c100200230.lua"
        if (!file.match(/c\d{9}\.lua$/)) continue;
        res = await pExecFile('git', ['log', '-p', '-n1', '--format=/%at', '--', file], { cwd: process.cwd() });
        let match = res.stdout.match(/^\/(?<time>\d+)[\s\S]+\ndeleted file.+\n[\s\S]+@@\n(?<header>---[\s\S]+?)\r?\n-(local|function)/m);
        let fileres;
        if (match) {
            fileres = { file, time: parseInt(match.groups.time), header: match.groups.header.replace(/^-/mg, '').replace(/\r\n/g, '\n') };
            if (fileres.time < 1656604000) { //2022-07-01 00:00:00 UTC
                break;
            }
        } else if (fs.existsSync(file)) {
            let filetext = fs.readFileSync(file, 'utf8');
            let time = parseInt(fs.statSync(file).birthtimeMs / 1000);
            match = filetext.match(/^(?<header>--[\s\S]+?)\r?\n(local|function)/);
            if (match) {
                fileres = { file, time, header: match.groups.header.replace(/\r\n/g, '\n') };
            }
            else {
                console.log("no match", file);
            }
        } else {
            console.log("no found", file);
        }
        //console.log(fileres);
        if (fileres) {
            fileres.file = fileres.file.replace(/^scripts\//, '');
            fileres.date = new Date(fileres.time * 1000).toISOString().replace(/T.+/, '');
            match = fileres.header.match(/([Cc]oded|[Ss]cript(ed)?) by\:? (?<writer>[^&\n]+)/);
            if (match) {
                fileres.writer = match.groups.writer.trim();
            }
            else {
                switch (fileres.file) {
                    case 'DBWS-JP/c100420027.lua':
                        fileres.writer = "JoyJ"; // https://github.com/Fluorohydride/ygopro-pre-script/pull/1061
                        break;
                    case 'CYAC-JP/c101112012.lua':
                        fileres.writer = "奥克斯"; // https://github.com/Fluorohydride/ygopro-pre-script/pull/1036
                        break;
                    case 'DABL-JP/c101110070.lua':
                        fileres.writer = "Ejeffers1239"; // https://github.com/Fluorohydride/ygopro-pre-script/pull/996
                        break;
                    default:
                        console.log("no writer", fileres);
                        break;
                }
            }
            //console.log(fileres);
            fileDatas.push(fileres);
        }
    }
    let outcsv = fs.createWriteStream('committer.csv', { encoding: 'utf8' });
    outcsv.write("\ufefffile,date,writer\n");
    for (let fileData of fileDatas) {
        outcsv.write(`${fileData.file},${fileData.date},${fileData.writer}\n`);
    }
    outcsv.end();
})();
