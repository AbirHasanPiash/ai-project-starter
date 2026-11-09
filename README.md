# Week 0 starter kit

Everything that `week_0_setup_guide.html` (one folder up) asks you to create.
The guide explains every file line by line. This page is the map.

```
week_0_starter/
├── week0_doctor.sh          checks the whole setup; read-only (add --repos for ~/code)
├── new_project.sh           creates ONE project: local folder, first commit, public repo
├── create_all_repos.sh      runs new_project.sh for P0–P6 (asks before touching GitHub)
├── pyproject_tools.toml     ruff + pytest settings appended to each pyproject.toml
├── template/                copied into every new project
│   ├── .github/workflows/ci.yml   lint + format check + tests on every push and PR
│   ├── .pre-commit-config.yaml    whitespace, YAML/TOML, big files, secrets, ruff
│   ├── .env.example               the keys a project needs, with empty values
│   ├── .gitignore                 secrets, caches, data and models stay out of git
│   ├── .vscode/                   recommended extensions and Python settings
│   ├── Makefile                   make setup | check | test | eval | keys | up | down
│   ├── README.md                  the roadmap's README template, with a status line
│   ├── LICENSE                    MIT
│   ├── tests/test_smoke.py        proves the package imports
│   ├── evals/                     where eval sets and the CI eval gate will live
│   └── scripts/check_providers.py tests every API key and Langfuse (make keys)
└── extras/
    ├── check_torch.py       PyTorch + Apple GPU (MPS) check: uv run check_torch.py
    └── pgvector/            Postgres 18 + pgvector in Docker, with a demo query
```

Quick start, after Parts 1–5 of the guide:

```bash
cp -R ~/Documents/my_profile/resources/AI_Engineer_Roadmap/week_0_starter ~/code/ai-project-starter
cd ~/code/ai-project-starter
./week0_doctor.sh
./create_all_repos.sh --local-only   # try it locally first; delete ~/code/<repo> folders after
./create_all_repos.sh                # the real run: seven public repos
./week0_doctor.sh --repos
```

Change the template here once, and every project you create afterwards gets the change.
