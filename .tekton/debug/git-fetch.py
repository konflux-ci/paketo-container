import traceback

import git
import argparse
import traceback
from git.exc import GitCommandError

class FetchError(Exception):
    """Custom exception for fetch errors."""
    pass

def fetch_git_tags(repo_path):
    """Fetch tags from a Git repository and handle any exceptions."""
    try:
        # Open the Git repository at the given path
        repo = git.Repo(repo_path)

        # Get the current commit (HEAD)
        commit = repo.commit(repo.rev_parse("HEAD").hexsha)
        print(f"Current commit: {commit}")

        # Fetch tags from the remote repository
        repo.remote().fetch(force=True, tags=True)
        print(f"Tags fetched successfully for repository: {repo.working_tree_dir}")

    except GitCommandError as ex:
        # Capture and print the stack trace
        traceback.print_exc()

        # Raise a custom exception if fetching tags fails
        raise FetchError(
            f"Failed to fetch the tags on the Git repository ({type(ex).__name__}) "
            f"for {repo.working_tree_dir}"
        ) from ex

# Example usage
if __name__ == "__main__":
    # Setup argument parser
    parser = argparse.ArgumentParser(description="Fetch tags from a Git repository.")

    # Define the repository path argument
    parser.add_argument(
        "repo_path",
        type=str,
        help="The path to the Git repository"
    )

    # Parse the arguments
    args = parser.parse_args()

    # Call the function with the provided repo path
    try:
        fetch_git_tags(args.repo_path)
    except FetchError as e:
        print(str(e))