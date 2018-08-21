import * as React from "react";
import User from "./interfaces/user";
import UsersSearch from "./interfaces/users_search";
import { stripHyphens as stripHyphensFromPhoneNumbers } from "./formatters/phone_number";
import { searchForUsers, deleteUser } from "./api";
import { SearchField } from "./components/search_field";
import { UsersTable } from "./components/users_table";
import { ConfirmDeleteUserModal } from "./components/confirm_delete_user_modal";

interface UserSearchPageState {
  usersSearch: UsersSearch;
  userForDeletion: User;
}

export class UserSearchPage extends React.Component {
  state: UserSearchPageState;

  constructor(props: any) {
    super(props);

    this.state = {
      usersSearch: {
        hasResults: false,
        isSearching: false
      },
      userForDeletion: null
    };
  }

  handleSearchRequest = (query: string) => searchForUsers(stripHyphensFromPhoneNumbers(query));

  handleUsersSearchUpdate = (usersSearch: UsersSearch) => this.setState({ usersSearch });

  confirmDeleteUser = (userForDeletion: User) => this.setState({ userForDeletion });

  finalizeUserDeletion = async () => {
    const res = await deleteUser(this.state.userForDeletion.id);

    // Remove deleted user from the list
    this.setState({
      usersSearch: {
        ...this.state.usersSearch,
        results: this.state.usersSearch.results.filter(user => user.id !== res.id)
      }
    });

    // Close delete confirmation modal
    this.setState({ userForDeletion: null });
  };

  cancelDelete = () => this.setState({ userForDeletion: null });

  render() {
    const { hasResults, isSearching, query, results } = this.state.usersSearch;

    return (
      <div className="user-search-page">
        <h1>Administration</h1>

        <SearchField searchForUsers={this.handleSearchRequest} onUpdate={this.handleUsersSearchUpdate} />

        <UsersTable
          hasResults={hasResults}
          isSearching={isSearching}
          query={query}
          users={results}
          deleteUser={this.confirmDeleteUser}
        />

        <ConfirmDeleteUserModal
          user={this.state.userForDeletion}
          deleteUser={this.finalizeUserDeletion}
          cancelDelete={this.cancelDelete}
        />
      </div>
    );
  }
}
