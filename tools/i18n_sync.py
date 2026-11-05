# -*- coding: utf-8 -*-
"""英語の表(i18n/en/*.json)をソースとそろえる。

ソース(core/ scenes/ ui/)の中の、日本語をふくむ文字列リテラルを全部ひろい、
出てきたファイルごとに i18n/en/<フォルダ>-<ファイル名>.json へ
  {"日本語の文": "英語の文"}
の形で持つ。まだ訳していない文は "" で入る。

  python tools/i18n_sync.py            # 表をそろえ、未訳と不要になった鍵の数を出す
  python tools/i18n_sync.py --prune    # ソースから消えた鍵を表からも消す
  python tools/i18n_sync.py --todo     # 未訳の鍵を出す(ファイル別)

最後に、全部をまとめた i18n/en.json(アプリが読む 1 枚の表)を書き出す。
同じ日本語の文が複数のファイルに出るときは、先に出たファイルの表だけに持つ。

除くもの: core/ruby.gd(よみの辞書)、core/ruby_corpus.gd、tests/、tools/、addons/。
"""
import glob
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
OUT_DIR = os.path.join(PROJ, "i18n", "en")
MERGED = os.path.join(PROJ, "i18n", "en.json")

SKIP = {"ruby.gd", "ruby_corpus.gd"}
# 日本語(かな・漢字・全角の記号)。core/lang.gd の has_ja と同じ範囲
JA = re.compile(u"[぀-ヿ一-鿿、-〃〈-】！-～]")
LIT = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


def unescape(s):
    """GDScript の文字列リテラルの中身を実際の文字列に"""
    return (s.replace("\\n", "\n").replace("\\t", "\t").replace('\\"', '"')
             .replace("\\\\", "\\"))


def strip_comment(line):
    """行末コメントを落とす(文字列の中の # は残す)"""
    out = []
    in_str = False
    i = 0
    while i < len(line):
        c = line[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < len(line):
                out.append(line[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
        else:
            if c == "#":
                break
            if c == '"':
                in_str = True
            out.append(c)
        i += 1
    return "".join(out)


def source_files():
    files = []
    for d in ("core", "scenes", "ui"):
        files += sorted(glob.glob(os.path.join(PROJ, d, "*.gd")))
    return [f for f in files if os.path.basename(f) not in SKIP]


def extract():
    """ファイル別に、出てきた順の日本語リテラル(重複なし)を返す"""
    per_file = {}
    for f in source_files():
        keys = []
        seen = set()
        src = io.open(f, encoding="utf-8").read()
        for line in src.splitlines():
            if line.lstrip().startswith("#"):
                continue
            code = strip_comment(line)
            for m in LIT.finditer(code):
                s = unescape(m.group(1))
                if JA.search(s) and s not in seen:
                    seen.add(s)
                    keys.append(s)
        if keys:
            # core/daily.gd と scenes/daily.gd のように 同じ 名前が あるので、フォルダ名を 頭に 付ける
            per_file[os.path.basename(os.path.dirname(f)) + "-"
                     + os.path.splitext(os.path.basename(f))[0]] = keys
    return per_file


def load(path):
    if not os.path.exists(path):
        return {}
    with io.open(path, encoding="utf-8") as fp:
        return json.load(fp)


def dump(path, data):
    with io.open(path, "w", encoding="utf-8", newline="\n") as fp:
        json.dump(data, fp, ensure_ascii=False, indent=1)
        fp.write("\n")


def main():
    prune = "--prune" in sys.argv
    todo = "--todo" in sys.argv
    os.makedirs(OUT_DIR, exist_ok=True)
    per_file = extract()

    # 先に出たファイルが鍵を持つ(同じ文を 2 か所で訳さない)
    owner = {}
    for name, keys in per_file.items():
        for k in keys:
            owner.setdefault(k, name)

    # 既にどこかの表に訳があれば、持ち主が変わっても訳を引きつぐ
    existing = {}
    for path in glob.glob(os.path.join(OUT_DIR, "*.json")):
        for k, v in load(path).items():
            if v and k not in existing:
                existing[k] = v

    merged = {}
    untranslated = 0
    stale_total = 0
    todo_lines = []
    for name, keys in per_file.items():
        path = os.path.join(OUT_DIR, name + ".json")
        table = load(path)
        new_table = {}
        for k in keys:
            if owner[k] != name:
                continue
            v = table.get(k, "") or existing.get(k, "")
            new_table[k] = v
            if v == "":
                untranslated += 1
                todo_lines.append("%s\t%s" % (name, k.replace("\n", "\\n")))
            else:
                merged[k] = v
        stale = [k for k in table if k not in new_table]
        stale_total += len(stale)
        if not prune:
            for k in stale:
                new_table[k] = table[k]
        dump(path, new_table)
    # ソースに出なくなった表ファイルは、鍵が全部不要になったということ
    for path in glob.glob(os.path.join(OUT_DIR, "*.json")):
        name = os.path.splitext(os.path.basename(path))[0]
        if name not in per_file:
            stale_total += len(load(path))
            if prune:
                os.remove(path)

    dump(MERGED, merged)
    total = sum(len(v) for v in per_file.values())
    print("keys %d (unique %d) / untranslated %d / stale %d%s" % (
        total, len(owner), untranslated, stale_total, " (pruned)" if prune else ""))
    if todo:
        for l in todo_lines:
            print(l)
    return 0


if __name__ == "__main__":
    sys.exit(main())
