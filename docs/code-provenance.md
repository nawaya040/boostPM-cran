# boostPM code provenance

## Scope

This note records the relationship among the archived source, the repository cited by the paper, and the public experiment scripts. Inspection was read-only. No file under `original/` was changed.

## Confirmed lineage

### Archived source

- Repository: <https://github.com/nawaya040/boostPM.git>
- Branch: `master`
- Commit: `1732dba73d3788c9c457f958c4e5699f12ff3bab`
- Commit time: 2023-10-09 11:24:30 +09:00
- Commit message: `Reflected the change in the boosting function`

### Repository cited by the paper

- Repository: <https://github.com/MaStatLab/boostPM.git>
- Branch: `master`
- Inspected HEAD: `b3dec3d3370c97b8dbb33db6ec3b7396c2b94650`
- HEAD time: 2023-10-12 10:19:56 +09:00

**confirmed from Git history**

`MaStatLab/boostPM` contains the archived commit `1732dba73d3788c9c457f958c4e5699f12ff3bab` as the direct parent of `b3dec3d3370c97b8dbb33db6ec3b7396c2b94650`.

The only change from `1732dba` to `b3dec3d` is one README installation line:

```text
install_github("nawaya040/boostPM")
```

changed to:

```text
install_github("MaStatLab/boostPM")
```

There is no difference in `DESCRIPTION`, `NAMESPACE`, `R/`, `src/`, `Example/`, or `man/`. The archived implementation is therefore code-identical to the implementation at the repository cited by the paper's current HEAD, apart from README provenance text.

### Experiment repository

- Repository: <https://github.com/MaStatLab/boostPM_experiments.git>
- Initial code commit: `1f20e18190698cf41e1d16e2a3d877d763947185`
- Commit time: 2023-10-09 11:25:44 +09:00
- Inspected HEAD: `786b82bb422b9ceca54d2f510023649c5b61c446`

**confirmed from Git history**

The initial experiment-code commit was created 74 seconds after the archived boostPM commit. The experiment scripts install `MaStatLab/boostPM` without pinning a commit. Their package API and tuning arguments match the archived implementation.

## Provenance conclusion

**confirmed**

The source preserved under `original/` belongs to the same Git history as the boostPM repository cited by the published paper. It is the final implementation commit immediately before the repository URL was changed from the author's account to the MaStatLab organization.

For source-level reconstruction, `original/` is an appropriate immutable baseline.

**unresolved**

The exact runtime environment and checked-out commit used to generate every published numerical result cannot be proven from the repositories alone. The experiment scripts contain no lockfile, package commit pin, `sessionInfo()`, result hashes, or archived output. The timing and code identity provide strong evidence, but not exact execution provenance.

## Other branch

The `nawaya040/boostPM` remote also contains an unrelated `main` branch whose current tree is a different package named `BATTS`. No local merge-base with the archived boostPM `master` branch was obtained. It is outside the boostPM lineage used here.

## Preservation decision

- Keep `original/` fixed at `1732dba73d3788c9c457f958c4e5699f12ff3bab`.
- Do not replace it with `b3dec3d`; the implementation files are identical.
- Record any future comparison against `MaStatLab/boostPM` separately.
- Treat exact reproduction of paper tables and figures as inferential or numerical validation until the original runtime environment is reconstructed.
