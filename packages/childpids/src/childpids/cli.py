import psutil
import typer
from typing import Annotated

app = typer.Typer()


@app.command()
def main(
    pid: Annotated[
        int,
        typer.Argument(),
    ],
):
    process = psutil.Process(pid)
    print(process.pid)
    for child in process.children(recursive=True):
        print(child.pid)


if __name__ == "__main__":
    app()  # pragma: no cover
