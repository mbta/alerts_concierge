import * as React from "react";
import User from "../interfaces/user";
import { UserRow } from "./user_row";

interface UsersTableProps {
  hasResults: boolean;
  isSearching: boolean;
  query: string;
  users: Array<User>;
  deleteUser: (user: User) => any;
};

const searchInstructionsRow = () => (
  <tr className="users-table--row_no-users">
    <td colSpan={3}>
      Search to see accounts.
    </td>
  </tr>
);

const searchingRow = () => (
  <tr className="users-table--row_searching">
    <td colSpan={3}>
      Searching…
    </td>
  </tr>
);

const noResultsRow = (query: string) => (
  <tr className="users-table--row_no-results">
    <td colSpan={3}>
      No accounts for “{query}” found.
    </td>
  </tr>
);

const usersTableContent = (props: UsersTableProps) => {
  const { hasResults, isSearching, query, users, deleteUser } = props;

  if (isSearching)
    return searchingRow();

  if (!hasResults)
    return searchInstructionsRow();

  if (!users.length)
    return noResultsRow(query);

  return users.map(user => <UserRow key={user.email} user={user} deleteUser={deleteUser} />)
};

export const UsersTable = (props: UsersTableProps) => (
  <table className="table table-bordered table-striped users-table">
    <thead className="thead-dark">
      <tr>
        <th>Subscriber email</th>
        <th>Phone number</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      {usersTableContent(props)}
    </tbody>
  </table>
);
