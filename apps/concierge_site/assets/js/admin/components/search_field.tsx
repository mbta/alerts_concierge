import * as React from "react";
import User from "../interfaces/user";
import UsersSearch from "../interfaces/users_search";

interface SearchForUsersFunction {
  (query: string): Promise<any>
}

interface HandleUsersSearchUpdateFunction {
  (usersSearch: UsersSearch): any;
}

interface SearchFieldProps {
  searchForUsers: SearchForUsersFunction;
  onUpdate: HandleUsersSearchUpdateFunction;
}

const inputRef: React.RefObject<HTMLInputElement> = React.createRef();

const handleSubmit = (searchForUsers: SearchForUsersFunction, onUpdate: HandleUsersSearchUpdateFunction) => async (event: React.FormEvent) => {
  event.preventDefault();
  const query = inputRef.current.value;

  onUpdate({
    hasResults: false,
    isSearching: true
  })

  const results: Array<User> = await searchForUsers(query)
  onUpdate({
    hasResults: true,
    isSearching: false,
    query,
    results
  });
}

export const SearchField = (props: SearchFieldProps) => (
  <form onSubmit={handleSubmit(props.searchForUsers, props.onUpdate)} className="user-search--form">
    <button type="submit" className="btn btn-primary user-search--submit">
      <i className="fa fa-search"></i>
    </button>
    <input
      type="search"
      ref={inputRef}
      className="user-search--field form-control"
      placeholder="Search by email or phone number"
      aria-label="Search by email or phone number"
      autoFocus={true}
    />
  </form>
);
