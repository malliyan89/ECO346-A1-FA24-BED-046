"""Question 5: reproduce the Question 3 band table and figure in Python.

Standalone script. Reads the local PSLM CSV files, computes weighted literacy
rates by age band and sex for variant 6 (rural Balochistan), writes the band
table, and saves figures/literacy_python.svg.
"""

import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
FIG = ROOT / "figures"
OUT = ROOT / "outputs"
FIG.mkdir(exist_ok=True)
OUT.mkdir(exist_ok=True)

# ---- Data -----------------------------------------------------------------
person = pd.read_csv(DATA / "pslm_person_subset.csv")
hh = pd.read_csv(DATA / "pslm_hh_subset.csv")

stop = hh["hhid"].duplicated().any()
if stop:
    raise ValueError("hhid is not unique in the household file")

dat = person.merge(
    hh[["hhid", "hhweight", "prov_code", "urban_rural"]],
    on="hhid", how="left", validate="many_to_one"
)
if len(dat) != len(person) or dat["hhweight"].isna().any():
    raise ValueError("Merge failed: missing weights")

variant = dat[(dat["prov_code"] == 4) & (dat["urban_rural"] == 1)].copy()

lit = variant[
    variant["age"].between(10, 64) & variant["literate"].notna()
].copy()

bands = [f"{a}-{a+4}" for a in range(10, 65, 5)]
edges = list(range(10, 70, 5))
lit["band"] = pd.cut(lit["age"], bins=edges, right=False, labels=bands)


def wmean(x, w):
    x = np.asarray(x, dtype=float)
    w = np.asarray(w, dtype=float)
    return float(np.sum(x * w) / np.sum(w))


rows = []
for band in bands:
    rec = {"band": band}
    for sex, name in ((2, "female"), (1, "male")):
        s = lit[(lit["band"] == band) & (lit["sex"] == sex)]
        rec[f"{name}_n"] = int(len(s))
        rec[f"{name}_rate"] = 100.0 * wmean(s["literate"], s["hhweight"])
    rec["gap_pp"] = rec["male_rate"] - rec["female_rate"]
    rows.append(rec)

bt = pd.DataFrame(rows)
bt = bt[["band", "male_n", "male_rate", "female_n", "female_rate", "gap_pp"]]
bt.to_csv(OUT / "band_table_python.csv", index=False)

# ---- Figure ---------------------------------------------------------------
col_female = "#D55E00"
col_male = "#0072B2"
mid = np.arange(12, 63, 5)
bt["mid"] = mid

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 10,
    "axes.titlesize": 12.2,
    "axes.labelsize": 10.5,
    "xtick.labelsize": 9,
    "ytick.labelsize": 9,
    "svg.fonttype": "none",
    "svg.hashsalt": "eco346",
})

fig, ax = plt.subplots(figsize=(8.2, 5.7))
fig.subplots_adjust(left=0.075, right=0.965, top=0.90, bottom=0.225)

for name, colour in (("Women", col_female), ("Men", col_male)):
    key = "female" if name == "Women" else "male"
    rate = bt[f"{key}_rate"].to_numpy()
    n = bt[f"{key}_n"].to_numpy()
    ax.plot(mid, rate, color=colour, linewidth=0.75, zorder=2)
    for x, y, nn in zip(mid, rate, n):
        face = "white" if nn < 30 else colour
        ax.plot(x, y, marker="o", markersize=5.6, markerfacecolor=face,
                markeredgecolor=colour, markeredgewidth=0.9, linestyle="none",
                zorder=3)

# Direct labels at the end of each series, no legend.
ax.text(63.2, bt["female_rate"].iloc[-1], "Women", color=col_female,
        fontsize=9.5, fontweight="bold", va="center", ha="left")
ax.text(63.2, bt["male_rate"].iloc[-1], "Men", color=col_male,
        fontsize=9.5, fontweight="bold", va="center", ha="left")

# Largest gap: 40-44.
gap = bt.loc[bt["gap_pp"].abs().idxmax()]
gap_mid = float(gap["mid"])
gap_f = float(gap["female_rate"])
gap_m = float(gap["male_rate"])
gap_pp = abs(float(gap["gap_pp"]))
ax.annotate(
    "", xy=(gap_mid - 0.55, gap_m), xytext=(gap_mid - 0.55, gap_f),
    arrowprops=dict(arrowstyle="<->", color="grey", linewidth=0.8,
                    shrinkA=0, shrinkB=0)
)
ax.text(gap_mid - 0.95, (gap_f + gap_m) / 2,
        f"Largest gap\n{gap_pp:.1f} pp",
        color="#333333", fontsize=9.5, ha="right", va="center",
        linespacing=0.9)

ax.set_xlim(10, 66)
ax.set_ylim(0, 100)
ax.set_xticks(mid)
ax.set_xticklabels(bands)
ax.set_yticks(np.arange(0, 101, 20))
ax.set_xlabel("Age band (years)")
ax.set_ylabel("Weighted literacy rate (%)")
ax.set_title(
    "Women's literacy trails men's at every age; the gap peaks at 48 points",
    loc="left", fontweight="bold", pad=10
)

ax.grid(axis="y", color="#EBEBEB", linewidth=0.8)
ax.grid(axis="x", visible=False)
ax.set_axisbelow(True)
ax.tick_params(axis="both", which="both", length=0)
for spine in ax.spines.values():
    spine.set_visible(False)

caption = (
    "Source: PSLM 2019-20 person and household files.\n"
    f"Sample: {len(lit):,} persons aged 10-64 in rural Balochistan with non-missing literacy.\n"
    "Weighted by hhweight. Hollow markers flag cells with <30 persons; none were thin."
)
fig.text(0.072, 0.015, caption, ha="left", va="bottom", fontsize=7.6,
         color="#595959", linespacing=1.2)

svg_path = FIG / "literacy_python.svg"
fig.savefig(svg_path, format="svg")
plt.close(fig)

# Keep the SVG byte-for-byte reproducible: matplotlib writes the current
# time into the RDF metadata. Replace it with a fixed date.
svg_text = svg_path.read_text(encoding="utf-8")
svg_text = re.sub(r"<dc:date>[^<]*</dc:date>",
                  "<dc:date>2026-10-26T00:00:00</dc:date>", svg_text)
svg_path.write_text(svg_text, encoding="utf-8")

# ---- Printed numbers ------------------------------------------------------
w1519 = float(bt.loc[bt["band"] == "15-19", "female_rate"].iloc[0])
m1519 = float(bt.loc[bt["band"] == "15-19", "male_rate"].iloc[0])
w5559 = float(bt.loc[bt["band"] == "55-59", "female_rate"].iloc[0])
m5559 = float(bt.loc[bt["band"] == "55-59", "male_rate"].iloc[0])
thin = int(((bt["male_n"] < 30) | (bt["female_n"] < 30)).sum())

lines = [
    f"Q5 (Python) literacy sample: {len(lit)}",
    f"Q5 (Python) women 15-19: {w1519:.1f}",
    f"Q5 (Python) men 15-19: {m1519:.1f}",
    f"Q5 (Python) women 55-59: {w5559:.1f}",
    f"Q5 (Python) men 55-59: {m5559:.1f}",
    f"Q5 (Python) largest gap: {gap['band']}, {gap_pp:.1f} pp",
    f"Q5 (Python) thin cells (<30): {thin}",
]
(OUT / "q5_numbers.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
print("Wrote figures/literacy_python.svg and outputs/band_table_python.csv")
